# frozen_string_literal: true

require_relative "youtube_update/pubsub"
require_relative "youtube_update/commands"

module YoutubeUpdate
  extend Plugin

  include! PubSub
  include! Commands
end
