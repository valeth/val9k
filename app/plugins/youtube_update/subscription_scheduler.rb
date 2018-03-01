# frozen_string_literal: true

require "json"
require "rest-client"
require "rufus-scheduler"
require "retriable"

module YoutubeUpdate
  module SubscriptionScheduler
    SubscriptionFailed = Class.new(StandardError)

    WEBSUB_URL = ENV.fetch("WEBSUB_URL")
    INTERVAL = 2.days.freeze
    @scheduler = Rufus::Scheduler.new

    def @scheduler.on_error(job, exception)
      LOGGER.error { exception.message }
    end

    Thread.new do
      LOGGER.info { "Starting YouTube subscription scheduler..." }
      YoutubeChannel.all.each { |chan| schedule(chan.channel_id) }
    end

  module_function

    # @param channel_id [String]
    # @return [YoutubeChannel]
    def subscribe(channel_id)
      chan = YoutubeChannel.find_by(channel_id: channel_id)
      return chan if chan && chan.next_update > DateTime.now

      response = RestClient.get("#{WEBSUB_URL}/subscribe/#{channel_id}")

      chan = youtube_channel(channel_id, JSON.parse(response.body)["channel_name"])
      chan.next_update = DateTime.now.advance(seconds: INTERVAL.to_i)
      chan.save
      LOGGER.info { "Updated, next update: #{chan.next_update}" }
      chan
    rescue RestClient::ExceptionWithResponse, Errno::ECONNREFUSED, ActiveRecord::ConnectionTimeoutError => e
      raise SubscriptionFailed, "Updating subscription for #{channel_id} failed: #{e.class}"
    end

    # Schedule a channel for resubscription
    # @param channel_id [String]
    # @return [YoutubeChannel]
    def schedule(channel_id)
      chan = YoutubeChannel.find_by(channel_id: channel_id)
      return chan if chan && scheduled?(channel_id)
      chan = subscribe(channel_id) if chan.nil?

      Thread.new do
        first_at = chan.next_update <= DateTime.now ? (Time.now + 10) : chan.next_update

        LOGGER.info do
          "Scheduling #{chan} for resubscription every #{INTERVAL.inspect}, first at #{first_at}"
        end

        # TODO: change retry mechanism
        @scheduler.every("#{INTERVAL.to_i}s", first_at: first_at, tag: channel_id) do
          Retriable.retriable(
            tries: 5,
            multiplier: 7,
            on: SubscriptionFailed,
            on_retry: proc do |exception, try, _elapsed_time, next_interval|
              LOGGER.error { "retry #{try}: #{exception.message}, retrying in #{next_interval.round(2)} seconds" }
            end
          ) do
            subscribe(channel_id)
          end
        end
      end

      chan
    end

    def unschedule(chan)
      return unless chan && scheduled?(chan)

      LOGGER.info { "Unscheduling #{chan.name} (#{chan.channel_id}) from resubscription..." }

      job, _ = @scheduler.jobs(tag: chan.channel_id)
      @schedulers.unschedule(job) if job
    end

    # @param channel_id [String]
    # @return [Boolean]
    def scheduled?(channel_id)
      job, _ = @scheduler.jobs(tag: channel_id)
      job.nil? ? false : @scheduler.scheduled?(job)
    end

    # @param id [String]
    # @param name [String]
    # @return [YoutubeChannel]
    def youtube_channel(id, name = nil)
      YoutubeChannel.find_or_create_by(channel_id: id) do |m|
        m.name        = name
        m.next_update = DateTime.now
      end
    end
  end
end
