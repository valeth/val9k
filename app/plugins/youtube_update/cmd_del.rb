# frozen_string_literal: true

module YoutubeUpdate
  module CommandDel
    extend Discordrb::Commands::CommandContainer
    extend Utils

    command(
      %i[delyoutubeupdate delytupd],
      required_permissions: %i[manage_webhooks],
      min_args: 2,
      usage: "delyoutubeupdate Jim Sterling #youtube_updates"
    ) do |event, *channel_name, chan_mention|
      update_cid = parse_channel_mention(chan_mention)
      next "Channel mention required as second argument" unless update_cid

      subscription = YoutubeNotificationSubscription.find_by(
        discord_channel: DiscordChannel.find_by(cid: update_cid),
        youtube_channel: YoutubeChannel.find_by(name: channel_name.join(" "))
      )
      if subscription&.destroy
        "Removed #{chan_mention} from update channel list for `#{subscription.youtube_channel.name}`"
      else
        "Failed to remove #{chan_mention} from update channel list"
      end
    end

  end
end
