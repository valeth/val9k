require "discordrb"

class Discordrb::Message
  def try_delete
    server = @channel.server
    bot_profile = @bot.profile.on(server)
    if bot_profile.permission?(:manage_messages, @channel)
      delete
    else
      LOGGER.warn do
        "Failed to delete message on #{server.name} in #{@channel.name} due to missing permissions."
      end
    end
    nil
  end
end
