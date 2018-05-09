# frozen_string_literal: true

require "active_support/core_ext/string/inflections"

class Uptime
  attr_reader :timestamp

  def initialize
    @timestamp = DateTime.now.freeze
  end

  def elapsed
    DateTime.now.to_i - self.to_i
  end

  def uptime
    timestamp = elapsed
    seconds = timestamp % 60
    minutes = (timestamp / 60) % 60
    hours = (timestamp / (60 * 60) % 24)
    days = (timestamp / (60 * 60 * 24))
    [days, hours, minutes, seconds]
  end

  def to_i
    @timestamp.to_i
  end

  def to_s
    days, hours, minutes, seconds = uptime
    fmt = []
    fmt << "#{days} day".pluralize(days) unless days.zero?
    fmt << "#{hours} hour".pluralize(hours) unless hours.zero?
    fmt << "#{minutes} minute".pluralize(minutes) unless minutes.zero?
    fmt << "#{seconds} second".pluralize(seconds) unless seconds.zero?
    fmt.join(", ")
  end
end
