# frozen_string_literal: true

require "erb"
require "yaml"
require "active_support/core_ext/hash/keys"
require "active_support/core_ext/string/inflections"
require "redis"
require "discordrb"

require "application_logger"
require "utils"
require "database"
require "events"
require "commands"

class VAL9K < Discordrb::Commands::CommandBot
  VERSION = "0.2.0"

  attr_reader :database
  attr_reader :redis

  def initialize
    @config = {}
    @database = nil
    @redis = nil

    load_config

    super(@config)
    initialize_database
    initialize_redis

    include! Events
    include! Commands

    load_plugins
  end

private

  def load_config
    config_file = File.expand_path("../config/discord.yml", __dir__)
    yml = YAML.safe_load(ERB.new(open(config_file).read).result)
    @config = yml.deep_symbolize_keys
  end

  def load_plugins
    plugin_path = File.expand_path("plugins", __dir__)
    Dir["#{plugin_path}/*.rb"].each do |file|
      require file
      plugin = File.basename(file, ".rb").classify
      LOGGER.info { "Adding plugin #{plugin}..." }
      include! plugin.constantize
    end
  end

  def initialize_database
    @database = Database.connect
  end

  def initialize_redis
    @redis = Redis.new
  end
end
