# frozen_string_literal: true

require_relative "subscription_scheduler"

module YoutubeUpdate
  module Commands
    extend Discordrb::Commands::CommandContainer
    extend Utils

    command(:yt_updates,
      description: "Receive youtube upload notifications.",
      usage: "yt_updates UCtxoI129gkBWW8_kNgJrxdQ #youtube_updates",
      required_permissions: %i[manage_webhooks]
    ) do |event, *args|
      update_channel_id = parse_channel_mention(args[2])
      yt_id = args[1]

      case args.first
      when "add"
        next "Channel mention required as second argument" unless update_channel_id
        add_channel(update_channel_id, yt_id)
      when "del"
        next "Channel mention required as second argument" unless update_channel_id
        del_channel(update_channel_id, yt_id)
      when "list"
        list_channels(event.server.id)
      end
    end

  module_function

    # @param cid [Integer]
    # @param yt_channel_id [String]
    # @return [YoutubeNotificationSubscription]
    def add_channel(cid, yt_channel_id)
      chan = SubscriptionScheduler.schedule(yt_channel_id)
      YoutubeNotificationSubscription.create do |m|
        m.youtube_channel = chan
        m.discord_channel = DiscordChannel.find_by(cid: cid)
      end
    rescue SubscriptionScheduler::SubscriptionFailed
      "Error!"
    else
      "Added #{mention_channel(cid)} to update channel list for `#{yt_channel_id}`."
    end

    # @param cid [Integer]
    # @param yt_channel_id [String]
    def del_channel(cid, yt_channel_id)
      subscription = YoutubeNotificationSubscription.find_by(
        discord_channel_id: cid,
        youtube_channel_id: yt_channel_id
      )
      subscription.destroy

      "Removed #{mention_channel(cid)} from update channel list for `#{yt_channel_id}`."
    end

    # @param sid [Integer]
    def list_channels(sid)
      subs = YoutubeNotificationSubscription
        .joins(:discord_channel)
        .where("discord_channels.sid" => sid)

      return if subs.empty?

      code_block do
        tmp = subs.map do |x|
          "#{x.youtube_channel.name} => #{x.discord_channel.cid}"
        end
        tmp.join("\n")
      end
    end
  end
end
