# frozen_string_literal: true

require "json"
require "active_support/core_ext/hash/keys"
require_relative "notification"

module YoutubeUpdate
  module PubSub
    extend Discordrb::EventContainer
    extend Notification
    include Loggable

    @subscriber = nil

    ready do |event|
      start_redis_subscriber(event.bot) unless @subscriber
    end

  module_function

    # @param bot [Discordrb::Bot]
    def start_redis_subscriber(bot)
      @subscriber ||= Thread.new do
        log.info { "Starting Redis YouTube subscriber listener..." }

        bot.redis.subscribe("youtube_updates") do |on|
          on.message do |channel, message|
            notify_all(bot, JSON.parse(message).symbolize_keys)
          end
        end
      end
      @subscriber.name = "Notifier"
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
      return if notif.published_at < bot.uptime.timestamp
      discord_channel = bot.channel(sub.discord_channel_id)
      msg = notification_role(discord_channel.server) || ""
      discord_channel.send_embed(msg, embed(notif))
      sub.notified(notif)
      log.info do
        "Sent nofication for #{sub.youtube_channel} to #{discord_channel.name} (#{discord_channel.id})"
      end
    rescue StandardError => err
      log.error do
        "Failed to send notification for #{sub.youtube_channel}: #{err.message}"
      end
    end

    # @param server [Discordrb::Server]
    # @return [String, nil]
    def notification_role(server)
      role_id = Notification.role(server.id)
      return unless role_id

      role = server.role(role_id)
      return role.mention if role

      # role is invalid, remove it
      log.info do
        "Removing youtube notification role for #{server.name} (#{server.id})"
      end
      ServerSettings.set(server.id, "youtube_update_role", role: nil)
      nil
    end
  end
end
