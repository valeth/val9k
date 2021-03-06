# frozen_string_literal: true

require "erb"
require "yaml"
require "active_support/core_ext/hash/keys"
require "active_support/core_ext/string/inflections"
require "redis"
require "discordrb"
require "discordrb/message"

require "application_logger"
require "utils"
require "database"
require "plugin"
require "events"
require "commands"
require "uptime"
require "set"

Thread.abort_on_exception = (ENV["DISCORD_ENV"] == "development") || !ENV["THREAD_ABORT_ON_EXCEPTION"].nil?

trap "SIGINT" do
  LOGGER.info { "Keyboard interrupt, Exiting..." }
  exit(0)
end

trap "SIGTERM" do
  exit(0)
end

class VAL9K < Discordrb::Commands::CommandBot
  include Loggable

  VERSION = "0.3.1"

  attr_reader :database
  attr_reader :redis
  attr_reader :uptime
  attr_accessor :ignored

  def initialize
    @config = {}
    @database = nil
    @redis = nil
    @uptime = Uptime.new
    @ignored = {
      servers: Set.new
    }

    load_config

    super(@config)
    at_exit { stop }

    initialize_ignores
    initialize_database
    initialize_redis

    include! Events
    include! Commands

    load_plugins
  end

  def log_exception(e)
    if e.is_a? Discordrb::Errors::NoPermission
      log.error { "Permission Error: #{e.message}" }
    else
      super(e)
    end
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
      log.info { "Adding plugin #{plugin}..." }
      include! plugin.constantize
    end
  end

  def initialize_database
    @database = Database.connect
  end

  def initialize_redis
    @redis = Redis.new
  end

  def initialize_ignores
    @ignored[:servers] += ENV.fetch("VAL9K_SERVER_IGNORES", []).chomp.split(",").map(&:to_i)
    log.info { "Ignoring #{@ignored[:servers].size} servers" }
    # @ignored[:users] += ENV.fetch("VAL9K_USER_IGNORES", []).chomp.split(",").map(&:to_i)
  end
end
