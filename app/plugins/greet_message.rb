require "json"

module GreetMessage
  extend Discordrb::Commands::CommandContainer
  extend Discordrb::EventContainer

  command :greetmsg do |event, *args|
    greetmsg = args.join(" ")
    msg = greet_message(event.server.id)

    if args.empty?
      next (msg&.content || "No greetmessage set.")
    end

    if msg
      msg.content = greetmsg
      msg.save
    else
      ServerMessage.create do |m|
        m.sid = event.server.id
        m.msg_type = "greet_message"
        m.content  = greetmsg
      end
    end
  end

  command :greetmsg_status, max_args: 0 do |event|
    status = greet_message_enabled?(event.server.id) ? "enabled" : "disabled"
    "Greet Message: #{status}"
  end

  command :greetmsg_toggle, max_args: 0 do |event|
    greet_message_toggle(event.server.id)
    if greet_message_enabled?(event.server.id)
      "Enabled greet messages."
    else
      "Disabled greet messages."
    end
  end

  member_join do |event|
    next unless greet_message_enabled?(event.server.id)
    LOGGER.info("#{event.user.name} joined #{event.server.name}")
    greet_channel = event.server.default_channel
    greetmsg = greet_message(event.server.id)&.content
    next unless greetmsg
    greetmsg.gsub!("{user}", event.user.name)
    greetmsg.gsub!("{server}", event.server.name)
    greet_channel.send(greetmsg)
  end

    module_function

  def greet_message_enabled?(sid)
    params = { sid: sid, key: "toggle_greetmsg" }
    query = ServerSetting.find_by(params)
    if query
      JSON.parse(query.value)["enabled"]
    else
      false
    end
  end

  def greet_message(sid)
    params = { sid: sid, msg_type: "greet_message" }
    ServerMessage.find_by(params)
  end

  def greet_message_toggle(sid)
    params = { sid: sid, key: "toggle_greetmsg" }
    msg = ServerSetting.find_by(params)
    if msg
      current = JSON.parse(msg.value)
      current["enabled"] = !current["enabled"]
      msg.value = JSON.generate(current)
      msg.save
    else
      ServerSetting.create do |m|
        m.sid = sid
        m.key = "toggle_greetmsg"
        m.value = JSON.generate(enabled: true)
      end
    end
  end
end
