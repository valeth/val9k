# frozen_string_literal: true

require "active_record_migrations"
require "dotenv"

Dotenv.load

ActiveRecordMigrations.configure do |config|
  config.yaml_config = "config/database.yml"
  config.environment = ENV.fetch("DISCORD_ENV") { "development" }
end

ActiveRecordMigrations.load_tasks

task run: "db:migrate" do
  trap("SIGINT") { exit(0) }
  trap("SIGTERM") { exit(0) }
  ruby "bin/bot"
end

task console: "db:migrate" do
  ruby "bin/console"
end

task default: :run
