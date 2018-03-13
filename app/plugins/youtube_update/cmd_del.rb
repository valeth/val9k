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
      channel_name = channel_name.join(" ")
      update_cid = parse_channel_mention(chan_mention)
      next "Channel mention required as second argument" unless update_cid

      subscription = YoutubeNotificationSubscription.find_by(
        discord_channel: DiscordChannel.find_by(cid: update_cid),
        youtube_channel: YoutubeChannel.find_by(name: channel_name)
      )
      if subscription&.destroy
        "Notifications for `#{subscription.youtube_channel.name}` will no longer be sent to #{chan_mention}."
      else
        "Failed to remove notification subscription for `#{channel_name}` to #{chan_mention}."
      end
    end
  end
end
