# Core event handlers

require "logging"

module Events
  extend Discordrb::EventContainer

  ready do |event|
    bot = event.bot
    LOGGER.info("Logged in as #{bot.profile.name}")
    game = "#{bot.prefix}help"
    LOGGER.info("Setting game to #{game}")
    bot.game = game

    update_channel_database(event.bot)
  end

  channel_create do |event|
    update_channel_database(event.bot, action: :create)
  end

  channel_delete do |event|
    update_channel_database(event.bot, action: :delete)
  end

  server_create do |event|
    update_channel_database(event.bot, action: :create)
  end

  server_delete do |event|
    update_channel_database(event.bot, action: :delete)
  end

  module_function

  # TODO: optimize this
  def channels_in_db
    DiscordChannel.all.map { |x| [x.sid, x.cid] }
  end

  # TODO: optimize this
  def channels_from_bot(bot)
    bot.servers.flat_map do |sid, srv|
      srv.channels.map { |x| [sid, x.id] }
    end
  end

  def update_channel_database(bot, action: nil)
    ch_local, ch_remote = channels_in_db, channels_from_bot(bot)

    case action
    when :create
      fill_channel_database(ch_local, ch_remote)
    when :delete
      cleanup_channel_database(ch_local, ch_remote)
    else
      fill_channel_database(ch_local, ch_remote)
      cleanup_channel_database(ch_local, ch_remote)
    end
  end

  def cleanup_channel_database(channels_local, channels_remote)
    only_local = channels_local - channels_remote
    # LOGGER.info("Only Local: #{only_local.size}")

    DiscordChannel.transaction do
      only_local.each do |sid, cid|
        DiscordChannel.find_by(sid: sid, cid: cid).delete
      end
    end
  end

  def fill_channel_database(channels_local, channels_remote)
    only_remote = channels_remote - channels_local
    # LOGGER.info("Only Remote: #{only_remote.size}")

    DiscordChannel.transaction do
      only_remote.each do |sid, cid|
        DiscordChannel.create(sid: sid, cid: cid)
      end
    end
  end
end
