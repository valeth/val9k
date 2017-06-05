module Owner
  extend Discordrb::Commands::CommandContainer

  command :eval, help_available: false do |event, *code|
    next unless event.author.id == 217078934976724992

    eval(code.join(" "))
  end

  command :kill, help_available: false do |event|
    next unless event.author.id == 217078934976724992

    event.channel.send("Shutting down...")
    exit
  end
end
