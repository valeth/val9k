# frozen_string_literal: true

require_relative "subscription_scheduler"

module YoutubeUpdate
  module Commands
    extend Discordrb::Commands::CommandContainer
    extend Utils

    command(
      %i[youtubeupdates ytupd],
      description: "Receive youtube upload notifications.",
      usage: "youtubeupdates add|del|list UCtxoI129gkBWW8_kNgJrxdQ #youtube_updates"
    ) do |event, subcmd, *args|
      bot = event.bot

      case subcmd
      when "add"  then bot.execute_command(:addyoutubeupdate, event, args)
      when "del"  then bot.execute_command(:delyoutubeupdate,  event, args)
      when "list" then bot.execute_command(:listyoutubeupdates, event, [])
      else %Q{Unknown subcommand "#{subcmd}"}
      end
    end

    command(
      %i[addyoutubeupdate addytupd],
      required_permissions: %i[manage_webhooks],
      min_args: 2,
      max_args: 2,
      usage: "addyoutubeupdate UCtxoI129gkBWW8_kNgJrxdQ #youtube_updates"
    ) do |event, yt_cid, chan_mention, *args|
      update_cid = parse_channel_mention(chan_mention)
      next "Channel mention required as second argument" unless update_cid

      begin
        chan = SubscriptionScheduler.schedule(yt_cid)
        YoutubeNotificationSubscription.create do |m|
          m.youtube_channel = chan
          m.discord_channel = DiscordChannel.find_by(cid: update_cid)
        end
      rescue SubscriptionScheduler::SubscriptionFailed
        "Failed to add subscription"
      else
        "Added #{chan_mention} to update channel list for `#{chan.name}`"
      end
    end

    command(
      %i[delyoutubeupdate delytupd],
      required_permissions: %i[manage_webhooks],
      min_args: 2,
      max_args: 2,
      usage: "delyoutubeupdate UCtxoI129gkBWW8_kNgJrxdQ #youtube_updates"
    ) do |event, yt_cid, chan_mention, *args|
      update_cid = parse_channel_mention(chan_mention)
      next "Channel mention required as second argument" unless update_cid

      subscription = YoutubeNotificationSubscription.find_by(
        discord_channel: DiscordChannel.find_by(cid: update_cid),
        youtube_channel: YoutubeChannel.find_by(channel_id: yt_cid)
      )
      if subscription&.destroy
        "Removed #{chan_mention} from update channel list for `#{subscription.youtube_channel.name}`"
      else
        "Failed to remove #{chan_mention} from update channel list"
      end
    end

    command(
      %i[listyoutubeupdates lsytupd],
      max_args: 0,
      usage: "listyoutubeupdates"
    ) do |event|
      subs = YoutubeNotificationSubscription
        .joins(:discord_channel)
        .where("discord_channels.sid" => event.server.id)

      next "No update subscriptions on this server" if subs.empty?

      code_block do
        tmp = subs.map do |x|
          yt_chan = x.youtube_channel&.name
          d_chan = event.bot.channel(x.discord_channel_id)&.name
          next unless yt_chan && d_chan
          "#{yt_chan} => #{d_chan}"
        end
        tmp.compact.join("\n")
      end
    end
  end
end
