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
  end
end
