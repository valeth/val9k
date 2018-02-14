# frozen_string_literal: true

require "json"
require "rest-client"
require "timers"
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
  @scheduled = {}
  @timers = Timers::Group.new
  @hub = WebSub.new("https://pubsubhubbub.appspot.com").freeze

module_function

  def subscribe(chan)
    LOGGER.info { "Updating subscription for channel #{chan.name} (#{chan.channel_id})..." }

    response = @hub.subscribe(
      topic:    "https://www.youtube.com/xml/feeds/videos.xml?channel_id=#{chan.channel_id}",
      callback: ENV.fetch("WEBSUB_CALLBACK")
    )

    if response.code == 204
      chan.next_update = DateTime.now.advance(days: 2)
      chan.save
      LOGGER.info("Updated, next update: #{chan.next_update}")
    end
  end

  def schedule(chan, interval: 2.days)
    return if scheduled?(chan)

    LOGGER.info { "Scheduling #{chan.name} (#{chan.channel_id}) for resubscription in #{interval.inspect}..." }

    th = Thread.new do
      subscribe(chan) if DateTime.now >= chan.next_update

      @timers.every(interval.to_i) { subscribe(chan) }

      loop { @timers.wait }
    end

    th.name = "SubscriptionUpdater: #{chan.id}"

    @scheduled.update(chan.channel_id => th)
  end

  def unschedule(chan)
    return unless scheduled?(chan)

    LOGGER.info { "Unscheduling #{chan.name} (#{chan.channel_id}) from resubscription..." }

    @scheduled[chan.channel_id].exit
    @scheduled.delete(chan.channel_id)
  end

  def scheduled?(chan)
    @scheduled.key?(chan.channel_id)
  end
end
