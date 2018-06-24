# frozen_string_literal: true

require "rufus-scheduler"
require "retriable"
require_relative "request"
require "thread"

module YoutubeUpdate
  module SubscriptionScheduler
    INTERVAL = 2.days.freeze
    @scheduler = Rufus::Scheduler.new
    @subscriber_queue = Queue.new
    @subscriber_threads = []

    @tries = 4
    Retriable.configure do |config|
      config.contexts[:ytsub] = {
        tries: @tries,
        multiplier: 7,
        on: Request::SubscriptionFailed,
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

  module_function

    def subscriber_thread
      thread = Thread.new do
        loop do
          channel_id = @subscriber_queue.deq

          begin
            Retriable.with_context(:ytsub) do
              chan = Request.subscribe(channel_id, INTERVAL)
              LOGGER.info { "Updated subscription for #{chan}, next update: #{chan.next_update}" }
            end
          rescue Request::SubscriptionFailed
            LOGGER.error { "Failed subscribing #{channel_id} after #{@tries} tries, will try again in #{INTERVAL.inspect}." }
          end
        end
      end
      thread.name = "Subscriber"
      thread
    end

    # Schedule a channel for resubscription
    # @param channel_id [String]
    # @raises SubscriptionFailed
    # @return [YoutubeChannel]
    def schedule(channel_id)
      chan = YoutubeChannel.find_by(channel_id: channel_id)
      return chan if chan && scheduled?(channel_id)
      chan ||= Request.subscribe(channel_id, INTERVAL)

      Thread.new do
        # add 10 seconds padding, so the scheduler doesn't complain about starting jobs in the past
        next_update = chan.next_update <= DateTime.now ? Time.now + 10 : chan.next_update

        LOGGER.info { "Scheduling #{chan} for resubscription every #{INTERVAL.inspect}, first at #{next_update}" }

        @scheduler.every("#{INTERVAL.to_i}s", first_at: next_update, tag: channel_id) do
          @subscriber_queue.enq(channel_id)
        end
      end

      chan
    end

    # @param chan [YoutubeChannel]
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

    Thread.new do
      LOGGER.info { "Starting YouTube subscription scheduler..." }
      @subscriber_threads = 3.times.map { subscriber_thread }
      YoutubeChannel.all.each { |chan| schedule(chan.channel_id) }
    end
  end
end
