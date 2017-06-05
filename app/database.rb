# frozen_string_literal: true

require "erb"
require "yaml"
require "active_record"

require_relative "logging"

module Database
  MODEL_PATH = File.expand_path("models", __dir__)
  CONFIG_FILE = File.expand_path("../config/database.yml", __dir__)

  env = ENV["DISCORD_ENV"] || "development"

  LOGGER.info("Database environment set to #{env}")

  erb = ERB.new(open(CONFIG_FILE).read).result
  db_config = YAML.load(erb)

  ActiveRecord::Base.establish_connection(db_config[env])
  LOGGER.info("Connected to database")

  Dir["#{MODEL_PATH}/*.rb"].each do |file|
    require file
    LOGGER.info("Loaded database model: #{File.basename(file, '.rb')}")
  end
end
