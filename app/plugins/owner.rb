require "open-uri"

module Owner
  extend Plugin
  extend Utils

  cmd(
    :eval,
    help_available: false,
    description: "Evaluate ruby code."
  ) do |event, *code|
    next unless bot_owner?(event)

    begin
      code_block(syntax: :ruby) { eval(code.join(" ")) }
    rescue SyntaxError => e
      code_block { e }
    end
  end

  cmd(
    :kill,
    help_available: false,
    description: "Kill the current bot instance."
  ) do |event|
    next unless bot_owner?(event)

    event.channel.send("Shutting down...")
    exit
  end

  cmd(
    :setavatar,
    help_available: false,
    max_args: 1,
    description: "Set the bot's avatar image."
  ) do |event, *args|
    next unless bot_owner?(event)
    attachment = event.message.attachments.first

    next "Require image url or attachment" if attachment.nil? && args.empty?

    begin
      if attachment.nil?
        event.bot.profile.avatar = open(args.first)
      elsif attachment.image?
        event.bot.profile.avatar = open(attachment.url)
      else
        next "Attachment is not an image file"
      end
    rescue Errno::ENOENT
      "Failed to open file"
    else
      "Updated avatar image"
    end
  end

  cmd(
    :ignoreserver,
    help_available: false,
    min_args: 1,
    max_args: 1
  ) do |event, sid, *_args|
    next unless bot_owner?(event)

    server = event.bot.servers[sid.to_i]
    next "Could not find server with ID #{sid}" unless server
    next "Cannot ignore this server" if server.id == 217081703137542145

    if event.bot.ignored[:servers].include?(server.id)
      event.bot.ignored[:servers].delete(server.id)
      "#{server.name} (#{server.id}) is no longer ignored"
    else
      event.bot.ignored[:servers] << server.id
      "#{server.name} (#{server.id}) is now ignored"
    end
  end

module_function

  def bot_owner?(event)
    user = event.author
    cmd  = event.command.name

    if user.id == 217078934976724992
      true
    else
      log.warn { "User #{user.distinct} (#{user.id}) tried to use `#{cmd}`." }
      false
    end
  end
end
