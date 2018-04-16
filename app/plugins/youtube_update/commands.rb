# frozen_string_literal: true

require_relative "cmd_add"
require_relative "cmd_del"
require_relative "cmd_list"
require_relative "cmd_role"

module YoutubeUpdate
  module Commands
    extend Plugin

    include! CommandAdd
    include! CommandDel
    include! CommandList
    include! CommandRole

    cmd(
      %i[youtubeupdates ytupd],
      description: "Receive youtube upload notifications.",
      usage: "youtubeupdates add|del|list UCtxoI129gkBWW8_kNgJrxdQ #youtube_updates",
      skip_usage_log: true
    ) do |event, subcmd, *args|
      bot = event.bot

      case subcmd
      when "add"  then bot.execute_command(:addyoutubeupdate, event, args)
      when "del"  then bot.execute_command(:delyoutubeupdate,  event, args)
      when "list" then bot.execute_command(:listyoutubeupdates, event, [])
      when "role" then bot.execute_command(:youtubeupdaterole, event, args)
      else %Q{Unknown subcommand "#{subcmd}"}
      end
    end
  end
end
