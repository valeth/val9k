require "erb"
require "yaml"
require "active_support/core_ext/hash/keys"
require "active_support/core_ext/string/inflections"
require "discordrb"

require "logging"
require "database"
require "events"

class VAL9K < Discordrb::Commands::CommandBot
  def initialize
    @config = {}

    load_config

    super(@config)

    include! Events

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
      LOGGER.info("Adding plugin #{plugin}...")
      include! plugin.constantize
    end
  end
end
