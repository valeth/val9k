require "json"

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

    LOGGER.info("#{event.user.name} joined #{event.server.name}")
    greetmsg = greet_message(event.server.id)&.content

    next unless greetmsg

    greetmsg.gsub!("{user_name}", event.user.name)
    greetmsg.gsub!("{user}", event.user.mention)
    greetmsg.gsub!("{server}", event.server.name)

    event.server.default_channel.send(greetmsg)
  end

module_function

  def set(sid, text)
    msg = greet_message(sid)

    if msg
      msg.content = text
      msg.save
    else
      ServerMessage.create do |m|
        m.sid      = sid
        m.msg_type = "greet_message"
        m.content  = text
      end
    end

    "Greet message updated."
  end

  def get(sid)
    greet_message(sid)&.content || "No greetmessage set."
  end

  def status(sid)
    status = greet_message_enabled?(sid) ? "enabled" : "disabled"
    "Greet Message: #{status}"
  end

  def toggle(sid)
    msg = ServerSetting.find_by(sid: sid, key: "toggle_greetmsg")

    if msg
      current = JSON.parse(msg.value)
      current["enabled"] = !current["enabled"]
      msg.value = JSON.generate(current)
      msg.save
    else
      ServerSetting.create do |m|
        m.sid   = sid
        m.key   = "toggle_greetmsg"
        m.value = JSON.generate(enabled: true)
      end
    end

    status(sid)
  end

  def greet_message_enabled?(sid)
    setting = ServerSetting.find_by(sid: sid, key: "toggle_greetmsg")

    if setting
      JSON.parse(setting.value)["enabled"]
    else
      false
    end
  end

  def greet_message(sid)
    ServerMessage.find_by(sid: sid, msg_type: "greet_message")
  end
end
