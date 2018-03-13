# frozen_string_literal: true

require_relative "cmd_add"
require_relative "cmd_del"
require_relative "cmd_list"

module YoutubeUpdate
  module Commands
    extend Discordrb::Commands::CommandContainer

    include! CommandAdd
    include! CommandDel
    include! CommandList

    command(
      %i[youtubeupdates ytupd],
      description: "Receive youtube upload notifications.",
      usage: "youtubeupdates add|del|list UCtxoI129gkBWW8_kNgJrxdQ #youtube_updates"
    ) do |event, subcmd, *args|
      bot = event.bot

      case subcmd
      when "add"  then bot.execute_command(:addyoutubeupdate, event, args)
      when "del"  then bot.execute_command(:delyoutubeupdate,  event, args)
      when "list" then bot.execute_command(:listyoutubeupdates, event, [])
      else %Q{Unknown subcommand "#{subcmd}"}
      end
    end
  end
end
