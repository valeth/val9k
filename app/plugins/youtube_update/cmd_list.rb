# frozen_string_literal: true

module YoutubeUpdate
  module CommandList
    extend Plugin
    extend Utils

    cmd(
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
