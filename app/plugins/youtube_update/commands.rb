# frozen_string_literal: true

require "active_support/core_ext/hash/keys"      # symbolize_keys
require "active_support/core_ext/string/filters" # truncate
require "rest-client"
require_relative "subscription_scheduler"

module YoutubeUpdate
  module Commands
    extend Discordrb::Commands::CommandContainer
    extend Utils

    DiscordEmbedFooter = Discordrb::Webhooks::EmbedFooter

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
      usage: "addyoutubeupdate ChannelName #youtube_updates"
    ) do |event, *yt_channel, chan_mention|
      update_cid = parse_channel_mention(chan_mention)
      next "Channel mention required as second argument" unless update_cid

      begin
        channels = youtube_channel_id(yt_channel.join(" "))
        event.channel.send_embed do |embed|
          embed.title = "YouTube search results"
          embed.description = "#{channels.size} channels"
          embed.footer = DiscordEmbedFooter.new(text: "Input a number to select a channel")
          channels.each.with_index(1) do |chan, i|
            desc = chan[:description].empty? ? "No description" : chan[:description].truncate(200)
            embed.add_field(
              name: "#{i}. #{chan[:title]}",
              value: "[#{desc}](https://youtube.com/channel/#{chan[:id]})"
            )
          end
        end

        event.author.await(:"addyoutubeupdate_#{event.author.id}") do |choice_event|
          choice = choice_event.message.content

          if choice.match?(/^\d+$/)
            choice = choice.to_i
          else
            choice_event.send_temporary_message("That's not a number", 5)
            next
          end

          unless choice.between?(1, channels.size - 1)
            choice_event.send_temporary_message("Choice not in range", 5)
            next
          end

          yt_cid = channels.dig(choice.pred, :id)
          chan = SubscriptionScheduler.schedule(yt_cid)

          YoutubeNotificationSubscription.create do |m|
            m.youtube_channel = chan
            m.discord_channel = DiscordChannel.find_by(cid: update_cid)
          end
          choice_event.send_message("Added #{chan_mention} to update channel list for `#{chan.name}`")
        end

        nil
      rescue SubscriptionScheduler::SubscriptionFailed
        "Failed to add subscription"
      end
    end

    command(
      %i[delyoutubeupdate delytupd],
      required_permissions: %i[manage_webhooks],
      min_args: 2,
      max_args: 2,
      usage: "delyoutubeupdate ChannelName #youtube_updates"
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

  module_function

    # @param channel_name [String]
    # @return [Array<Hash>] The channel ID
    def youtube_channel_id(channel_name)
      results = RestClient.get("#{SubscriptionScheduler::WEBSUB_URL}/search",
        params: { channel_name: channel_name }
      )

      channels = JSON.parse(results)
      raise SubscriptionScheduler::SubscriptionFailed if channels.empty?

      channels.map { |chan| chan.symbolize_keys }
    end
  end
end
