require "json"
require "sinatra"
require "redis"
require_relative "youtube"

REDIS = Redis.new(driver: :hiredis)

puts "Connected to redis" if REDIS.connected?

get "/youtube" do
  challenge = params["hub.challenge"]
  status 200
  body challenge
end

post "/youtube" do
  hsh = process_youtube_xml(request.body.read)
  json = JSON.generate(hsh)
  REDIS.publish("youtube_updates", json)
  nil
end
