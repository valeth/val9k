# frozen_string_literal: true

require "json"
require "rest-client"

module WebSub
  URL = "https://pubsubhubbub.appspot.com"

  module_function

  def request(mode: :subscribe, verify: :sync, secret: nil, lease: nil, topic:, callback:)
    response = RestClient.post(URL,
      "hub.mode"          => mode,
      "hub.verify"        => verify,
      "hub.topic"         => topic,
      "hub.lease_seconds" => lease,
      "hub.secret"        => secret,
      "hub.callback"      => callback,
      "content_type"      => "application/x-www-form-urlencoded"
    )

    response.code == 204
  end

  def subscribe(**options)
    options[:mode] = :subscribe
    request(options)
  end

  def unsubscribe(**options)
    options[:mode] = :unsubscribe
    request(options)
  end
end

