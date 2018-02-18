# frozen_string_literal: true

require "json"
require "active_support/core_ext/hash/keys"

module YoutubeUpdate
  module PubSub
    extend Discordrb::EventContainer

    DiscordEmbed = Discordrb::Webhooks::Embed
    DiscordEmbedAuthor = Discordrb::Webhooks::EmbedAuthor
    DiscordEmbedImage = Discordrb::Webhooks::EmbedImage

    ready do |event|
      start_redis_subscriber(event.bot)
    end

  module_function

    # @param bot [Discordrb::Bot]
    def start_redis_subscriber(bot)
      Thread.new do
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
        .each do |sub|
          notif = notification(sub.youtube_channel, message)
          next if sub.notified?(notif)
          notify_one(bot.channel(sub.discord_channel_id), notif)
        end
    end

    def notify_one(discord_channel, notif)
      discord_channel.send_embed("", embed(notif))
    end

    # @param channel [YoutubeChannel]
    # @param messge [Hash<String => String>]
    # @return [YoutubeNotification]
    def notification(channel, message)
      YoutubeNotification.find_or_create_by(video_id: message[:youtube_video_id]) do |m|
        m.title           = message[:title]
        m.published_at    = message[:published]
        m.updated_at      = message[:updated]
        m.thumbnail_url   = message[:thumbnail_url]
        m.description     = message[:description]
        m.youtube_channel = channel
      end
    end

    # Build a Discord embed from a notification.
    # @param notif [YoutubeNotification]
    # @return [DiscordEmbed]
    def embed(notif)
      DiscordEmbed.new(
        title:  notif.title,
        url:    notif.url,
        author: DiscordEmbedAuthor.new(
          name:   notif.youtube_channel.name,
          url:    notif.youtube_channel.url
        ),
        image: DiscordEmbedImage.new(url: notif.thumbnail_url),
        timestamp: notif.published_at,
        color: 0xfc0c00
      )
    end
  end
end
