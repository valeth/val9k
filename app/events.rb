# Core event handlers

require_relative "application_logger"

module Events
  extend Discordrb::EventContainer
  include Loggable

  ready do |event|
    log.info { "Started at #{event.bot.uptime.timestamp}" }
    bot = event.bot
    log.info { "Logged in as #{bot.profile.name}" }
    game = "#{bot.prefix}help"
    log.info { "Setting game to #{game}" }
    bot.game = game
  end

  server_create do |event|
    log.info { "Joined #{event.server.name} (#{event.server.id})" }
    DiscordChannel.transaction do
      event.server.channels.each do |channel|
        DiscordChannel.create(sid: event.server.id, cid: channel.id)
      end
    end
  end

  server_delete do |event|
    log.info { "Left #{event.server.name} (#{event.server.id})" }
    DiscordChannel.where(sid: event.server.id).destroy_all
  end

  channel_create do |event|
    log.info do
      [
        "New", channel_type_str(event.type), "channel",
        "@", event.server.name, "(#{event.server.id})",
        "#", event.channel.name, "(#{event.channel.id})"
      ].compact.join(" ")
    end
    DiscordChannel.create(sid: event.server.id, cid: event.channel.id)
  end

  channel_delete do |event|
    DiscordChannel.find_by(sid: event.server.id, cid: event.id).destroy
  end

module_function

  def channel_type_str(channel_type)
    case channel_type
    when 0 then "text"
    when 1 then "private"
    when 2 then "voice"
    when 3 then "group"
    else nil
    end
  end
end
