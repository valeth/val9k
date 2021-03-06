# Core commands

require "utils"
require_relative "application_logger"

module Commands
  extend Plugin
  extend Utils

  cmd(
    :info,
    description: "General information about the bot."
  ) do |event|
    code_block(nil, syntax: :haskell) do
      <<~INFO
        Author:  Valeth
        License: GPLv3
        Source:  https://gitlab.com/valeth/val9k
      INFO
    end
  end

  cmd(
    :stats,
    help_available: false,
    description: "Just statistics."
  ) do |event|
    discordrb_gem = Gem::Specification.find_by_name("discordrb")
    code_block(nil, syntax: :haskell) do
      <<~STATS
        VAL9k Version:     #{VAL9K::VERSION}
        Discordrb Version: #{discordrb_gem.version}
        Ruby Version:      #{RUBY_ENGINE} #{RUBY_VERSION}
        Servers:           #{event.bot.servers.size}
        Users:             #{event.bot.users.size}
        Login Name:        #{event.bot.profile.name}
        Uptime:            #{event.bot.uptime}
      STATS
    end
  end

  cmd(
    :invite,
    help_available: false,
    description: "Invite the bot to a server."
  ) do |event|
    event.bot.invite_url
  end
end
