require "utils"

module Selfrole
  extend Discordrb::Commands::CommandContainer
  extend Utils

  options = {
    description: "Toggle a selfrole.",
    min_args: 1
  }
  command :selfrole, options do |event, *args|
    case args.first
    when "add"
      next "Not permitted!" unless event.author.permission?(:manage_roles)
      add(event.server, args[1..-1].join(" "))
    when "del"
      next "Not permitted!" unless event.author.permission?(:manage_roles)
      del(event.server, args[1..-1].join(" "))
    else
      toggle(event.server, event.author, args.join(" "))
    end
  end

  options = {
    description: "List all selfroles on this server.",
    max_args: 0
  }
  command :selfroles, options do |event|
    server = event.server
    roles = all(server.id).map { |e| server.role(e).name }
    if roles.empty?
      "No self-assignable roles on this server."
    else
      code_block(nil) do
        roles.join("\n")
      end
    end
  end

module_function

  def toggle(server, user, rname)
    sid = server.id
    rid = role_id(server, rname)
    return "Cannot find role *#{rname}*." unless rid
    return "Role *#{rname}* is not self-assignable!" unless selfrole?(sid, rid)

    role = server.role(rid)
    if user.role?(role)
      user.remove_role(role)
      "You no longer have the *#{rname}* role."
    else
      user.add_role(role)
      "You now have the *#{rname}* role."
    end
  end

  def del(server, rname)
    sid = server.id
    rid = role_id(server, rname)
    return "Cannot find role *#{rname}*." unless rid

    roles = selfroles(sid)
    tmp = JSON.parse(roles.value)
    deleted = tmp.delete(rid)
    return "*#{rname}* is not in the list of self-assignable roles." unless deleted
    roles.value = JSON.generate(tmp)
    roles.save

    "Removed *#{rname}* from list of self-assignable roles."
  end

  def add(server, rname)
    sid = server.id
    rid = role_id(server, rname)
    return "Cannot find role *#{rname}*." unless rid

    roles = selfroles(sid)
    tmp = JSON.parse(roles.value)
    tmp << rid
    roles.value = JSON.generate(tmp)
    roles.save

    "Added *#{rname}* to list of self-assignable roles."
  end

  def role_id(server, role_name)
    server.roles.find { |e| e.name == role_name }&.id
  end

  def selfroles(sid)
    roles = ServerSetting.find_by(sid: sid, key: "selfroles")
    return roles if roles
    ServerSetting.create do |m|
      m.sid = sid
      m.key = "selfroles"
      m.value = JSON.generate([])
    end
  end

  def selfrole?(sid, rid)
    all(sid).include?(rid)
  end

  def all(sid)
    roles = ServerSetting.find_by(sid: sid, key: "selfroles")
    if roles
      JSON.parse(roles.value)
    else
      []
    end
  end
end
