# frozen_string_literal: true

require_relative "youtube_update/pubsub"
require_relative "youtube_update/commands"

Thread.abort_on_exception = (ENV["DISCORD_ENV"] == "development")

module YoutubeUpdate
  extend Discordrb::EventContainer
  extend Discordrb::Commands::CommandContainer

  include! PubSub
  include! Commands
end
