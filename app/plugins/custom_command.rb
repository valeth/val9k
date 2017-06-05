require "utils"

module CustomCommand
  extend Discordrb::Commands::CommandContainer
  extend Discordrb::EventContainer
  extend Utils

  command :add_cmd, min_args: 2 do |event, cmd, *args|
    begin
      ServerCommand.create! do |m|
          m.name = cmd
          m.content = args.join(" ")
          m.sid = event.server.id
        end
      "Added command #{cmd}."
    rescue ActiveRecord::RecordInvalid => e
      "Failed to add command #{cmd}: #{e}"
    end
  end

  command :rm_cmd, min_args: 1, max_args: 1 do |event, cmd|
    m = ServerCommand.find_by(name: cmd)
    if m.nil?
      %(Command "#{cmd}" not found.)
    else
      m.destroy
      %(Command "#{cmd}" deleted.)
    end
  end

  command :list_cmds, max_args: 0 do |event|
    list(event.server.id)
  end

  message start_with: "!!" do |event|
    cmd = event.content[2..-1]
    next if cmd.empty?
    m = ServerCommand.find_by(name: cmd)
    if m.nil?
      event.channel.send("Command not found.")
    else
      event.channel.send(m.content)
    end
  end

    module_function

  def list(sid)
    cmds = ServerCommand.where(sid: sid).order(:created_at)
    if cmds.empty?
      "No custom commands on this server"
    else
      code_block(nil, syntax: :markdown) do
        msg = cmds.map { |x| x.name }.join("\n")
        "# Custom commands on this server:\n#{msg}"
      end
    end
  end
end
