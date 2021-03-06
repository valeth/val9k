# frozen_string_literal: true

require "erb"
require "yaml"
require "active_record"
require_relative "application_logger"

module Database
  include Loggable

  MODEL_PATH = File.expand_path("models", __dir__)
  CONFIG_FILE = File.expand_path("../config/database.yml", __dir__)

  ActiveRecord::Base.configurations = YAML.load(ERB.new(open(CONFIG_FILE).read).result)

module_function

  def connect
    env = ENV["DISCORD_ENV"]&.to_sym || :development
    log.info { "Database environment set to #{env}" }

    db = ActiveRecord::Base.establish_connection(env)
    log.info { "Connected to database" }

    load_models
    db
  end

  def load_models
    Dir["#{MODEL_PATH}/*.rb"].each do |file|
      require file
      log.info { "Loaded database model: #{File.basename(file, '.rb')}" }
    end
  end
end
