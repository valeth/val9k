# frozen_string_literal: true

require "active_support/core_ext/string/filters" # truncate
require_relative "request"
require_relative "subscription_scheduler"

module YoutubeUpdate
  module CommandAdd
    extend Discordrb::Commands::CommandContainer
    extend Utils

    DiscordEmbedFooter = Discordrb::Webhooks::EmbedFooter

    command(
      %i[addyoutubeupdate addytupd],
      required_permissions: %i[manage_webhooks],
      min_args: 2,
      usage: "addyoutubeupdate Jim Sterling #youtube_updates"
    ) do |event, *yt_channel, chan_mention|
      update_cid = parse_channel_mention(chan_mention)
      next "Channel mention required as second argument" unless update_cid

      channels = Request.search_channels(yt_channel.join(" "))
      list_search_results(event, channels)

      event.author.await(:"addyoutubeupdate_#{event.author.id}") do |choice_event|
        begin
          with_choice(choice_event, channels) do |yt_cid|
            chan = add_subscription(yt_cid, update_cid)
            choice_event.send_message("Added #{chan_mention} to update channel list for `#{chan.name}`")
          end
        rescue Request::SubscriptionFailed
          choice_event.send_message("Failed to add subscription")
        end
      end

      nil
    end

  module_function

    def with_choice(event, channels)
      choice = event.message.content
      number = choice.match?(/^\d+$/)
      choice = choice.to_i
      in_range = choice.between?(1, channels.size - 1)
      return event.send_temporary_message("That's not a number", 5) unless number
      return event.send_temporary_message("Choice not in range", 5) unless in_range
      yield(channels.dig(choice.to_i.pred, :id)) if block_given?
    end

    def list_search_results(event, channels)
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
    end

    def add_subscription(yt_cid, update_cid)
      chan = SubscriptionScheduler.schedule(yt_cid)
      YoutubeNotificationSubscription.create do |m|
        m.youtube_channel = chan
        m.discord_channel = DiscordChannel.find_by(cid: update_cid)
      end
      chan
    end
  end
end
