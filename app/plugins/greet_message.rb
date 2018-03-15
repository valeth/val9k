module GreetMessage
  extend Discordrb::Commands::CommandContainer
  extend Discordrb::EventContainer

  options = {
    required_permissions: %i[manage_server],
    description: "Control a server's greet message for joining users.",
    usage: "greetmsg [get | set <text> | toggle | status]"
  }
  command :greetmsg, options do |event, *args|
    sid = event.server.id

    next get(sid) if args.empty?

    case args.first
    when "get"    then get(sid)
    when "set"    then set(sid, args[1..-1].join(" "))
    when "toggle" then toggle(sid)
    when "status" then status(sid)
    end
  end

  member_join do |event|
    next unless greet_message_enabled?(event.server.id)

    LOGGER.info { "#{event.user.name} joined #{event.server.name}" }
    greetmsg = greet_message(event.server.id)

    next unless greetmsg

    greetmsg.gsub!("{user_name}", event.user.name)
    greetmsg.gsub!("{user}", event.user.mention)
    greetmsg.gsub!("{server}", event.server.name)

    event.server.default_channel.send(greetmsg)
  end

module_function

  def set(sid, text)
    msg = ServerMessage.find_or_initialize_by(sid: sid, msg_type: "greet_message")
    msg.content = text
    msg.save
    "Greet message updated."
  end

  def get(sid)
    greet_message(sid) || "No greetmessage set."
  end

  def toggle(sid)
    ServerSetting.set(sid, "toggle_greetmsg", enabled: false) do |s|
      { enabled: !s["enabled"] }
    end
    status(sid)
  end

  def status(sid)
    status = greet_message_enabled?(sid) ? "enabled" : "disabled"
    "Greet Message: #{status}"
  end

  def greet_message_enabled?(sid)
    ServerSetting.get(sid, "toggle_greetmsg").fetch("enabled", false)
  end

  def greet_message(sid)
    ServerMessage.find_by(sid: sid, msg_type: "greet_message")&.content
  end
end
