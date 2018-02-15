# frozen_string_literal: true

require "json"
require "rest-client"
require "rufus-scheduler"
require_relative "application_logger"

class WebSub
  def initialize(hub_url)
    @hub_url = hub_url
  end

  def subscribe(**options)
    options[:mode] = :subscribe
    request(options)
  end

  def unsubscribe(**options)
    options[:mode] = :unsubscribe
    request(options)
  end

private

  def request(mode: :subscribe, verify: :sync, secret: nil, lease: nil, topic:, callback:)
    RestClient.post(@hub_url, {
        "hub.mode"          => mode,
        "hub.verify"        => verify,
        "hub.topic"         => topic,
        "hub.lease_seconds" => lease,
        "hub.secret"        => secret,
        "hub.callback"      => callback,
      },
      "content_type" => "application/x-www-form-urlencoded"
    )
  rescue RestClient::ExceptionWithResponse => e
    LOGGER.error e.response
    e.response
  end
end

module YoutubeSubscriptionScheduler
  INTERVAL = 2.days.freeze
  @hub = WebSub.new("https://pubsubhubbub.appspot.com").freeze
  @scheduler = Rufus::Scheduler.new

module_function

  def subscribe(chan)
    LOGGER.info { "Updating subscription for channel #{chan.name} (#{chan.channel_id})..." }

    response = @hub.subscribe(
      topic:    "https://www.youtube.com/xml/feeds/videos.xml?channel_id=#{chan.channel_id}",
      callback: ENV.fetch("WEBSUB_CALLBACK")
    )

    if response.code == 204
      chan.next_update = DateTime.now.advance(seconds: INTERVAL.to_i)
      chan.save
      LOGGER.info("Updated, next update: #{chan.next_update}")
    end
  end

  def schedule(chan)
    return if scheduled?(chan)

    LOGGER.info { "Scheduling #{chan.name} (#{chan.channel_id}) for resubscription in #{INTERVAL.inspect}..." }

    Thread.new do
      subscribe(chan) if chan.next_update.nil? || DateTime.now >= chan.next_update

      @scheduler.every("#{INTERVAL.to_i}s", first_at: chan.next_update, tag: chan.channel_id) do
        subscribe(chan)
      end
    end
  end

  def unschedule(chan)
    return unless scheduled?(chan)

    LOGGER.info { "Unscheduling #{chan.name} (#{chan.channel_id}) from resubscription..." }
    job, _ = @scheduler.jobs(tag: chan.channel_id)
    @schedulers.unscheduler(job) if job
  end

  def scheduled?(chan)
    job, _ = @scheduler.jobs(tag: chan.channel_id)
    job.nil? ? false : @scheduler.scheduled?(job)
  end
end
