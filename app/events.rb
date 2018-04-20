# Core event handlers

require_relative "application_logger"

module Events
  extend Discordrb::EventContainer

  ready do |event|
    LOGGER.info { "Started at #{event.bot.startup_timestamp}" }
    bot = event.bot
    LOGGER.info { "Logged in as #{bot.profile.name}" }
    game = "#{bot.prefix}help"
    LOGGER.info { "Setting game to #{game}" }
    bot.game = game
  end

  server_create do |event|
    DiscordChannel.transaction do
      event.server.channels.each do |channel|
        DiscordChannel.create(sid: event.server.id, cid: channel.id)
      end
    end
  end

  server_delete do |event|
    DiscordChannel.where(sid: event.server.id).destroy
  end

  channel_create do |event|
    DiscordChannel.create(sid: event.server.id, cid: event.id)
  end

  channel_delete do |event|
    DiscordChannel.find_by(sid: event.server.id, cid: event.id).destroy
  end
end
