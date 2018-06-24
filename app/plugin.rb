module Plugin
  include Discordrb::EventContainer
  include Discordrb::Commands::CommandContainer
  include Loggable

  def self.extended(mod)
    Loggable.extended(mod)
  end

  def cmd(name, attributes)
    command(name, attributes) do |event, *args|
      next if event.bot.ignored[:servers].include?(event.server.id)

      unless attributes.fetch(:skip_usage_log, false)
        log.info do
          tmp = "Executing #{event.command.name}(#{args.join(' ')})"
          tmp += " by #{event.author.distinct} (#{event.author.id})"
          tmp += " @ #{event.server.name} (#{event.server.id})" unless event.channel.pm?
          tmp += " # #{event.channel.name} (#{event.channel.id})" unless event.channel.pm?
          tmp
        end
      end
      yield(event, *args)
    end
  end
end
