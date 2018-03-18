# frozen_string_literal: true

require "json"
require "active_support/core_ext/hash/keys"
require_relative "notification"

module YoutubeUpdate
  module PubSub
    extend Discordrb::EventContainer
    extend Notification

    @subscriber = nil

    ready do |event|
      start_redis_subscriber(event.bot) unless @subscriber
    end

  module_function

    # @param bot [Discordrb::Bot]
    def start_redis_subscriber(bot)
      @startup_timestamp = DateTime.now.freeze
      @subscriber ||= Thread.new do
        LOGGER.info { "Starting Redis YouTube subscriber listener..." }

        bot.redis.subscribe("youtube_updates") do |on|
          on.message do |channel, message|
            notify_all(bot, JSON.parse(message).symbolize_keys)
          end
        end
      end
    end

    # @param bot [Discordrb::Bot]
    # @param message [Hash<String => String>]
    def notify_all(bot, message)
      YoutubeNotificationSubscription
        .joins(:youtube_channel)
        .where("youtube_channels.channel_id" => message[:youtube_channel_id])
        .each { |sub| notify_one(bot, sub, message) }
    end

    def notify_one(bot, sub, message)
      notif = notification(sub.youtube_channel, message)
      return if sub.notified?(notif)
      return if notif.published_at < @startup_timestamp
      discord_channel = bot.channel(sub.discord_channel_id)
      server = discord_channel.server
      role_id = Notification.role(server.id)
      msg = role_id ? server.role(role_id).mention : ""
      discord_channel.send_embed(msg, embed(notif))
      sub.notified(notif)
    end
  end
end
