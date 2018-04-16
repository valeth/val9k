module Accept
  extend Plugin

  cmd(
    :accept,
    max_args: 0
  ) do |event|
    server = event.server
    role_id = ServerSetting.get(server.id, "member_role", role: nil).fetch("role", nil)
    next "No member role set" unless role_id
    role = server.role(role_id)
    if event.author.role?(role)
      event.send_temporary_message("You already have the `#{role.name}` role.", 5)
    else
      event.author.add_role(role)
      event.send_temporary_message("You now have the `#{role.name}` role.", 5)
    end
    nil
  end

  cmd(
    :member_role,
    required_permissions: %i[manage_roles],
    max_args: 1
  ) do |event, role_name|
    if role_name
      toggle_member_role(event, role_name)
    else
      role_id = ServerSetting.get(event.server.id, "member_role", role: nil)&.fetch("role", nil)
      next "No member role set for this server" unless role_id
      role = event.server.role(role_id)
      "Role `#{role.name}` is used as member role."
    end
  end

module_function

  def toggle_member_role(event, role_name = nil)
    server = event.server
    if role_name == "none"
      ServerSetting.set(server.id, "member_role", role: nil)
      event.send_temporary_message("Member role unset.", 5)
    else
      role = server.roles.select { |x| x.name == role_name }&.first
      return "Can not find role #{role_name} on this server." unless role
      ServerSetting.set(server.id, "member_role", role: role.id)
      event.send_temporary_message("Role `#{role_name}` is now used as member role.", 5)
    end
    nil
  end
end
