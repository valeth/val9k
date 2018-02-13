require "json"
require "redis"
require "logging"
require "utils"
require "websub"

Thread.abort_on_exception = true
REDIS = Redis.new

module YoutubeUpdate
  extend Discordrb::Commands::CommandContainer
  extend Discordrb::EventContainer
  extend Utils

  # TODO: use YouTube API to query by channel name
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
    start_subscription_scheduler
  end

  module_function

  # TODO: Use YouTube API to get channel name

  # @param cid [Integer]
  # @param yt_channel_id [String]
  # @return [YoutubeNotificationSubscription]
  def add_channel(cid, yt_channel_id)
    YoutubeNotificationSubscription.create do |m|
      m.youtube_channel = youtube_channel(yt_channel_id)
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

  def list_channels(sid)
    subs = YoutubeNotificationSubscription
      .joins(:discord_channel)
      .where("discord_channels.sid" => sid)

    code_block(subs.map { |x| x.discord_channel.cid.to_s }.join("\n"))
  end

  # @param bot [Discordrb::Bot]
  def start_redis_subscriber(bot)
    Thread.new do
      LOGGER.info { "Starting Redis YouTube subscriber listener..." }

      REDIS.subscribe("youtube_updates") do |on|
        on.message do |channel, message|
          notify_all(bot, JSON.parse(message))
        end
      end
    end
  end

  def start_subscription_scheduler
    Thread.new do
      LOGGER.info { "Starting YouTube subscription scheduler..." }

      YoutubeChannel.all.each do |chan|
        YoutubeSubscriptionScheduler.schedule(chan)
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
    channel.send_embed("", notification.to_embed)
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

  # @param id [String]
  # @param name [String]
  # @return [YoutubeChannel]
  def youtube_channel(id, name = "")
    chan = YoutubeChannel.find_by(channel_id: id)

    if !chan
      chan = YoutubeChannel.create(channel_id: id, name: name)
      YoutubeSubscriptionScheduler.schedule(id)
    elsif !name.empty? && chan&.name != name
      chan.update(name: name)
    end

    chan
  end
end
