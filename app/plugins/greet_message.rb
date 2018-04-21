module GreetMessage
  extend Plugin
  extend Utils

  cmd(
    :greetmsg,
    required_permissions: %i[manage_server],
    description: "Control a server's greet message for joining users.",
    usage: "greetmsg [get | set <text> | toggle | status]"
  ) do |event, *args|
    sid = event.server.id

    next get(sid) if args.empty?

    case args.first
    when "get"    then get(sid)
    when "set"    then set(sid, args[1..-1].join(" "))
    when "toggle" then toggle(sid)
    when "status" then status(sid)
    when "channel" then channel(event, args[1])
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

    greet_channel(event).send(greetmsg)
  end

module_function

  def greet_channel(event)
    channel_id = ServerSetting.get(event.server.id, "greetmsg_channel")&.fetch("cid", nil)
    if channel_id
      event.bot.channel(channel_id)
    else
      event.server.default_channel
    end
  end

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

  def channel(event, channel)
    if channel
      channel_id = parse_channel_mention(channel)
      return "Channel mention required" unless channel_id
      ServerSetting.set(event.server.id, "greetmsg_channel", cid: channel_id)
      "Greet Channel set to: #{mention_channel(channel_id)}"
    else
      "Greet Channel: #{mention_channel(greet_channel(event).id)}"
    end
  end
end
