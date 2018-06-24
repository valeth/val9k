require "logging"
require "discordrb"
require "active_support/core_ext/kernel/reporting"

# STDOUT.sync = true

LOGLEVELS = {
  debug: :lime,
  info: :green,
  warn: :yellow,
  error: :red,
  fatal: %i[white on_red],
  exception: %i[white on_red],
  good: :green,
  out: :cyan,
  in: :purple
}.freeze

Logging.init(LOGLEVELS.keys)

Logging.color_scheme("bright",
  levels: LOGLEVELS,
  date: :blue,
  logger: :cyan,
  message: :magenta
)

Logging.appenders.stdout(
  "stdout",
  layout: Logging.layouts.pattern(
    pattern: "[%-5l] %d %c: %m\n",
    color_scheme: "bright"
  )
)

LOGGER = Logging.logger.root
LOGGER.level = :debug
LOGGER.appenders = :stdout

class DiscordLogger < Discordrb::Logger
  def initialize
    super
    @logger = Logging.logger["Discord"]
    @enabled_modes = %i[good info warn error ratelimit]
  end

  MODES.keys.each do |lvl|
    define_method(lvl) do |msg|
      @logger.public_send(lvl, msg) if @enabled_modes.include?(lvl)
    end
  end
end

silence_warnings do
  Discordrb::LOGGER = DiscordLogger.new
end

