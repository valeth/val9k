# frozen_string_literal: true

module YoutubeUpdate
  module Notification
    DiscordEmbed = Discordrb::Webhooks::Embed
    DiscordEmbedAuthor = Discordrb::Webhooks::EmbedAuthor
    DiscordEmbedImage = Discordrb::Webhooks::EmbedImage

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

  module_function

    def role(sid, rid = nil)
      if rid
        ServerSetting.set(sid, "youtube_update_role") do |s|
          { role: rid.to_i }
        end
      else
        ServerSetting.get(sid, "youtube_update_role", role: nil).fetch("role", nil)
      end
    end
  end
end
