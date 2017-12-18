require "sinatra"
require "dotenv"

Dotenv.load

set :env, :production
disable :run

require "./app/web/routes"

run Sinatra::Application
