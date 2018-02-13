# frozen_string_literal: true

require "ostruct"
require "cgi"
require "open-uri"
require "nokogiri"
require "logging"

module SteamSearch
  extend Discordrb::Commands::CommandContainer

  STEAM_BASE_URL = "https://store.steampowered.com/search"

  Embed = Discordrb::Webhooks::Embed

  options = {
    min_args: 1,
    description: "Search the Steam store.",
    usage: "steam <search query>"
  }
  command :steam, options do |event, *args|
    query = args.join(" ")
    event.channel.send_embed do |embed|
      embed.title = "Steam search results"
      embed.url = "#{STEAM_BASE_URL}?term=#{CGI.escape(query)}"
      search(query).take(5).each do |result|
        title = "[#{result.title}](#{result.link})"
        price = result.discount.empty? ? result.price : "#{result.price} (#{result.discount})"
        embed.add_field(name: price, value: title)
      end
    end
  end

module_function

  def search(query)
    steam_url = "#{STEAM_BASE_URL}?term=#{CGI.escape(query)}"
    doc = Nokogiri::HTML(open(steam_url))
    doc.css(".search_result_row").map do |elem|
      date = elem.css(".search_released").text
      OpenStruct.new(
        link: elem["href"],
        image: elem.css(".search_capsule > img").attr("src").text,
        title: elem.css(".search_name > .title").text,
        release_date: date.empty? ? nil : DateTime.parse(date),
        reviews: elem.css(".search_review_summary").first&.attr("data-store-tooltip"),
        price: elem.css(".search_price").children.last.text.strip,
        discount: elem.css(".search_discount").first.text.strip
      )
    end
  end
end
