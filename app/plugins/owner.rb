require "open-uri"

module Owner
  extend Discordrb::Commands::CommandContainer

  options = {
    help_available: false,
    description: "Evaluate ruby code."
  }
  command :eval, options do |event, *code|
    next unless bot_owner?(event)

    eval(code.join(" "))
  end

  options = {
    help_available: false,
    description: "Kill the current bot instance."
  }
  command :kill, options do |event|
    next unless bot_owner?(event)

    event.channel.send("Shutting down...")
    exit
  end

  options = {
    help_available: false,
    max_args: 1,
    description: "Set the bot's avatar image."
  }
  command :setavatar, options do |event, *args|
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

  module_function

  def bot_owner?(event)
    user = event.author
    cmd  = event.command.name

    if user.id == 217078934976724992
      true
    else
      LOGGER.warn("User #{user.distinct} (#{user.id}) tried to use `#{cmd}`.")
      false
    end
  end
end
