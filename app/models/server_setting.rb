require "json"

class ServerSetting < ActiveRecord::Base
  validates :sid, presence: true
  validates :key, presence: true, uniqueness: { scope: :sid }
  validates :value, presence: true

  # @param sid [Integer]
  # @param key [String]
  # @param default [Hash]
  # @return [Hash]
  def self.get(sid, key, default = {})
    setting = find_by(sid: sid, key: key)

    if setting
      json = JSON.parse(setting.value)
      yield(json) if block_given?
      json
    else
      default
    end
  end

  # @param sid [Integer]
  # @param key [String]
  # @param value [Hash]
  # @return [ServerSetting]
  def self.set(sid, key, value = {})
    setting = find_or_initialize_by(sid: sid, key: key)
    setting.value = JSON.generate(
      if block_given?
        if setting.value
          yield(JSON.parse(setting.value))
        else
          yield(value)
        end
      else
        value
      end
    )
    setting.save
    setting
  end
end
