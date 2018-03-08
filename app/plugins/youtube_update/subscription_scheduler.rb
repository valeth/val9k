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

    @tries = 4
    Retriable.configure do |config|
      config.contexts[:ytsub] = {
        tries: @tries,
        multiplier: 7,
        on: SubscriptionFailed,
        on_retry: proc do |err, try, _elapsed, next_interval|
          LOGGER.error do
            "try #{try}/#{@tries}: #{err.message}" +
            (", retrying in #{next_interval.round(2)} seconds" if next_interval).to_s
          end
        end
      }
    end

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
      response = RestClient.get("#{WEBSUB_URL}/subscribe/#{channel_id}")
      YoutubeChannel.find_or_create_by(channel_id: channel_id) do |m|
        m.name        = JSON.parse(response.body)["channel_name"]
        m.next_update = DateTime.now.advance(seconds: INTERVAL.to_i)
      end
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
        # add 10 seconds padding, so the scheduler doesn't complain about starting jobs in the past
        next_update = chan.next_update <= DateTime.now ? Time.now + 10 : chan.next_update

        LOGGER.info { "Scheduling #{chan} for resubscription every #{INTERVAL.inspect}, first at #{next_update}" }

        @scheduler.every("#{INTERVAL.to_i}s", first_at: next_update, tag: channel_id) do
          begin
            Retriable.with_context(:ytsub) do
              chan = subscribe(channel_id)
              LOGGER.info { "Updated, next update: #{chan.next_update}" }
            end
          rescue SubscriptionFailed
            LOGGER.error { "Failed subscribing #{channel_id} after #{@tries} tries, will try again in #{INTERVAL.inspect}." }
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
  end
end
