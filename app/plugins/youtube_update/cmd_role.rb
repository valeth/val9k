# frozen_string_literal: true

require_relative "notification"

module YoutubeUpdate
  module CommandRole
    extend Discordrb::Commands::CommandContainer

    command(%i[youtubeupdaterole ytupdrl],
      required_permissions: %i[manage_webhooks],
      max_args: 1
    ) do |event, mention = nil|
      sid = event.server.id
      if mention
        role = event.bot.parse_mention(mention)
        next "Role is not mentionable or invalid role mention" unless role
        Notification.role(sid, role.id)
        "Using role #{role.name} for future YouTube notifications."
      else
        role_id = Notification.role(sid)
        if role_id
          role = event.server.role(role_id)
          "Role #{role} is used for YouTube notifications."
        else
          "No notification role set on this server"
        end
      end
    end
  end
end
