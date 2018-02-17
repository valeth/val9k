require "json"
require "utils"
require "websub"
require "application_logger"
require "google/apis/youtube_v3"
require "discordrb"

Thread.abort_on_exception = (ENV["DISCORD_ENV"] == "development")

module YoutubeUpdate
  extend Discordrb::Commands::CommandContainer
  extend Discordrb::EventContainer
  extend Utils

  DiscordEmbed = Discordrb::Webhooks::Embed
  DiscordEmbedAuthor = Discordrb::Webhooks::EmbedAuthor
  DiscordEmbedImage = Discordrb::Webhooks::EmbedImage
  YouTube = Google::Apis::YoutubeV3

  YOUTUBE = YouTube::YouTubeService.new
  YOUTUBE.key = ENV.fetch("YOUTUBE_API_KEY")

  options = {
    description: "Receive youtube upload notifications.",
    usage: "yt_updates UCtxoI129gkBWW8_kNgJrxdQ #youtube_updates",
    required_permissions: %i[manage_webhooks]
  }
  command :yt_updates, options do |event, *args|
    update_channel_id = parse_channel_mention(args[2])
    yt_id = args[1]

    case args.first
    when "add"
      next "Channel mention required as second argument" unless update_channel_id
      add_channel(update_channel_id, yt_id)
      "Added #{args[2]} to update channel list for `#{yt_id}`."
    when "del"
      next "Channel mention required as second argument" unless update_channel_id
      del_channel(update_channel_id, yt_id)
      "Removed #{args[2]} from update channel list for `#{yt_id}`."
    when "list"
      list_channels(event.server.id)
    end
  end

  ready do |event|
    start_redis_subscriber(event.bot)
  end

  Thread.new do
    LOGGER.info { "Starting YouTube subscription scheduler..." }

    youtube_channels do |chan|
      YoutubeSubscriptionScheduler.schedule(chan)
    end
  end

  module_function

  # @param cid [Integer]
  # @param yt_channel_id [String]
  # @return [YoutubeNotificationSubscription]
  def add_channel(cid, yt_channel_id)
    chan = youtube_channel(yt_channel_id)
    YoutubeSubscriptionScheduler.schedule(chan)
    YoutubeNotificationSubscription.create do |m|
      m.youtube_channel = chan
      m.discord_channel = DiscordChannel.find_by(cid: cid)
    end
  end

  # @param cid [Integer]
  # @param yt_channel_id [String]
  def del_channel(cid, yt_channel_id)
    subscription = YoutubeNotificationSubscription.find_by(
      discord_channel_id: cid,
      youtube_channel_id: yt_channel_id
    )
    return unless subscription

    subscription.destroy
  end

  # @param sid [Integer]
  def list_channels(sid)
    subs = YoutubeNotificationSubscription
      .joins(:discord_channel)
      .where("discord_channels.sid" => sid)

    code_block do
      tmp = subs.map do |x|
        "#{x.youtube_channel.name} => #{x.discord_channel.cid}"
      end
      tmp.join("\n")
    end
  end

  # @param bot [Discordrb::Bot]
  def start_redis_subscriber(bot)
    Thread.new do
      LOGGER.info { "Starting Redis YouTube subscriber listener..." }

      bot.redis.subscribe("youtube_updates") do |on|
        on.message do |channel, message|
          notify_all(bot, JSON.parse(message))
        end
      end
    end
  end

  # @param bot [Discordrb::Bot]
  # @param message [Hash]
  def notify_all(bot, message)
    channel = youtube_channel(message["channel"]["id"], message["channel"]["name"])
    subscriptions = channel.youtube_notification_subscriptions

    subscriptions.each do |sub|
      discord_channel = bot.channel(sub.discord_channel_id)
      notif = notification(sub, channel, message)
      next if sub.notified?(notif)
      notify(discord_channel, notif)
      sub.youtube_notifications << notif
      sub.save
    end
  end

  # @param channel [Discordrb::Channel]
  # @param notification [YoutubeNotification]
  # @return [Discordrb::Message]
  def notify(channel, notification)
    channel.send_embed("", embed(notification))
  end

  # @param subscription [YoutubeNotificationSubscription]
  # @param channel [YoutubeChannel]
  # @param messge [Hash]
  # @return [YoutubeNotification]
  def notification(subscription, channel, message)
    notif = YoutubeNotification.find_by(video_id: message["id"])
    return notif if notif

    YoutubeNotification.create do |m|
      m.video_id        = message["id"]
      m.title           = message["title"]
      m.published_at    = message["published"]
      m.updated_at      = message["updated"]
      m.youtube_channel = channel
    end
  end

  def youtube_channels
    YoutubeChannel.all.each do |chan|
      chan.update(name: fetch_channel_title(chan.channel_id)) if chan.name&.empty?
      yield(chan)
    end
  end

  # @param id [String]
  # @param name [String]
  # @return [YoutubeChannel]
  def youtube_channel(id, name = nil)
    chan = YoutubeChannel.find_or_create_by(channel_id: id) do |m|
      m.name = name || fetch_channel_title(id)
    end

    chan.update(name: fetch_channel_title(id)) if chan.name&.empty?
    chan
  end

  # @param channel_id [String]
  # @return [String]
  def fetch_channel_title(channel_id)
    LOGGER.info { "Fetching channel name for #{channel_id}" }
    results = YOUTUBE.list_searches("snippet", type: "channel", channel_id: channel_id)
    results.items.first&.snippet&.title
  rescue Google::Apis::Error => e
    LOGGER.error { "Failed to fetch YouTube channel name: #{e}" }
    ""
  end

  # Get thumbnails with highest possible resolution
  # @param [Youtube::ThumbnailDetails]
  # @return [String, nil]
  def youtube_thumbnail(thumbs)
    (thumbs.maxres || thumbs.standard || thumbs.high || thumbs.medium || thumbs.default)&.url
  end

  # @param video_id [String]
  # @return [Hash]
  def fetch_video_info(video_id)
    LOGGER.info { "Fetching video info for #{video_id}" }
    results = YOUTUBE.list_videos("snippet", id: video_id)
    snippet = results.items.first&.snippet
    return unless snippet
    {
      thumbnail_url: youtube_thumbnail(snippet.thumbnails),
      description:   snippet.description,
      title:         snippet.title
    }
  rescue Google::Apis::Error => e
    LOGGER.error { "Failed to fetch YouTube video info: #{e}" }
    {}
  end

  # Build a Discord embed from a notification.
  # @param notif [YoutubeNotification]
  # @return [DiscordEmbed]
  def embed(notif)
    video_info = fetch_video_info(notif.video_id)

    DiscordEmbed.new(
      title: video_info[:title] || notif.title,
      # description: video_info[:description],
      url: notif.url,
      author: DiscordEmbedAuthor.new(
        name: notif.youtube_channel.name,
        url:  notif.youtube_channel.url
      ),
      image: DiscordEmbedImage.new(
        url: video_info[:thumbnail_url] || notif.thumbnail_url
      ),
      timestamp: notif.published_at,
      color: 0xfc0c00
    )
  end
end
