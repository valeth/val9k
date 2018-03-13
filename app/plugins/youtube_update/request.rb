# frozen_string_literal: true

require "active_support/core_ext/hash/keys" # symbolize_keys
require "rest-client"
require "json"

module YoutubeUpdate
  module Request
    SubscriptionFailed = Class.new(StandardError)
    WEBSUB_URL = ENV.fetch("WEBSUB_URL")

  module_function

    # @param channel_id [String]
    # @return [YoutubeChannel]
    def subscribe(channel_id, interval)
      response = RestClient.get("#{WEBSUB_URL}/subscribe/#{channel_id}")

      chan = YoutubeChannel.find_or_create_by(channel_id: channel_id) do |m|
        m.name        = JSON.parse(response.body)["channel_name"]
        m.next_update = DateTime.now.advance(seconds: interval.to_i)
      end
      chan.next_update = DateTime.now.advance(seconds: interval.to_i)
      chan.save

      chan
    rescue RestClient::ExceptionWithResponse, Errno::ECONNREFUSED, ActiveRecord::ConnectionTimeoutError => e
      raise SubscriptionFailed, "Updating subscription for #{channel_id} failed: #{e.class}"
    end

    # @param channel_name [String]
    # @return [Array<Hash>] List of search results
    def search_channels(channel_name)
      results = RestClient.get("#{WEBSUB_URL}/search",
        params: { channel_name: channel_name }
      )

      channels = JSON.parse(results)
      raise SubscriptionFailed if channels.empty?

      channels.map { |chan| chan.symbolize_keys }
    end
  end
end
