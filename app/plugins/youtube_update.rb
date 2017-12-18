require "thread"
require "json"
require "redis"
require "logging"
require "utils"

Thread.abort_on_exception = true
REDIS = Redis.new

module YoutubeUpdate
  extend Discordrb::Commands::CommandContainer
  extend Discordrb::EventContainer
  extend Utils

  EmbedAuthor = Discordrb::Webhooks::EmbedAuthor
  EmbedImage = Discordrb::Webhooks::EmbedImage

  @notifiers = {}
  @mutex = Mutex.new

  # TODO: use youtube API to get proper channel name and other info
  options = {
    description: "Receive youtube upload notifications.",
    usage: "yt_updates UCtxoI129gkBWW8_kNgJrxdQ #youtube_updates",
    required_permissions: %i[manage_webhooks],
    min_args: 2
  }
  command :yt_updates, options do |event, *args|
    server_id = event.server.id
    update_channel_id = parse_channel_mention(args[2])
    next "Channel mention required as second argument" unless update_channel_id
    yt_id = args[1]

    case args.first
    when "add"
      add_channel(update_channel_id, server_id, yt_id)
      "Added #{args[2]} to update channel list for `#{yt_id}`."
    when "del"
      del_channel(update_channel_id, server_id, yt_id)
      "Removed #{args[2]} from update channel list for `#{yt_id}`."
    end
  end

  ready do |event|
    restore_settings
    subscribe(event.bot)
  end

  module_function

  # (Integer, Integer, String) -> nil
  def add_channel(cid, sid, yt_channel_id)
    channels = youtube_update_channels(sid)
    mappings = JSON.parse(channels.value)

    @mutex.synchronize do
      @notifiers[yt_channel_id] ||= []
      @notifiers[yt_channel_id] << cid unless @notifiers[yt_channel_id].include?(cid)
    end

    mappings[yt_channel_id] ||= []
    mappings[yt_channel_id] << cid unless mappings.include?(cid)
    channels.value = JSON.generate(mappings)
    channels.save
  end

  # (Integer, Integer, String) -> nil
  def del_channel(cid, sid, yt_channel_id)
    channels = youtube_update_channels(sid)
    mappings = JSON.parse(channels.value)

    @mutex.synchronize do
      @notifiers[yt_channel_id].delete(cid)
    end

    mappings[yt_channel_id].delete(cid)
    channels.value = JSON.generate(mappings)
    channels.save
  end

  def youtube_update_channels(sid)
    channels = ServerSetting.find_by(sid: sid, key: "youtube_update_channels")
    return channels if channels
    ServerSetting.create do |m|
      m.sid = sid
      m.key = "youtube_update_channels"
      m.value = JSON.generate({})
    end
  end

  def restore_settings
    LOGGER.info { "Restoring youtube notification settings" }
    server_settings = ServerSetting.where(key: "youtube_update_channels")
    notifiers = {}

    server_settings.each do |server_setting|
      mappings = JSON.parse(server_setting.value)
      mappings.each do |yt_channel_id, channels|
        notifiers[yt_channel_id] ||= []
        notifiers[yt_channel_id] |= channels
      end
    end

    @mutex.synchronize { @notifiers = notifiers }
  end

  def subscribe(bot)
    Thread.new do
      LOGGER.info { "Starting redis subscriber..." }

      REDIS.subscribe("youtube_updates") do |on|
        on.message do |channel, message|
          data = JSON.parse(message)
          @mutex.synchronize do
            @notifiers.fetch(data["channel"], []).each do |notifier|
              chan = bot.channel(notifier)
              notify(chan, data)
            end
          end
        end
      end
    end
  end

  def notify(channel, json)
    channel.send_embed do |embed|
      embed.title = json["title"]
      embed.url = json["url"]
      embed.author = EmbedAuthor.new(
        name: json["author"],
        url: "https://youtube.com/channel/#{json['channel']}"
      )
      embed.image = EmbedImage.new(url: "https://img.youtube.com/vi/#{json['id']}/maxresdefault.jpg")
      embed.timestamp = DateTime.parse(json["published"])
      embed.color = 0xfc0c00
    end
  end
end
