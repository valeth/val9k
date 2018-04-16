require "application_logger"

module Moderator
  extend Plugin

  cmd(
    :prune,
    description: "Delete multiple messages from a channel.",
    usage: "prune 10 @mention",
    required_permissions: %i[manage_messages],
    max_args: 2,
    arg_types: [Integer, String]
  ) do |event, *args|
    chan   = event.channel
    user   = prune_target(event)
    amount = args.first || 10

    event.message.delete()
    messages = user_messages(chan, user, amount)
    msg =
      if messages.empty?
        "No messages to prune"
      elsif messages.size == 1
        chan.delete_message(messages.first)
        "#{event.author.name} deleted one message of #{user.name} from #{event.channel.mention}"
      else
        chan.delete_messages(messages)
        "#{event.author.name} deleted #{amount} messages of #{user.name} from #{event.channel.mention}"
      end

    LOGGER.info { msg }
    chan.send_temporary_message(msg, 5)
  end

module_function

  def prune_target(event)
    if event.message.mentions.empty?
      event.bot.profile
    else
      event.message.mentions.first
    end
  end

  def prune_amount(amount)
    amount || 10
  end

  def help_for(cmd)
    <<~RB
      **`#{cmd.name}`**: #{cmd.attributes[:description]}
      Usage: `#{cmd.attributes[:usage]}`
    RB
  end

  def user_messages(channel, user, amount = 10, depth = 5)
    before_id = nil

    messages =
      (1..depth).reduce([]) do |acc, _i|
        break acc if acc.size >= amount
        tmp = channel.history(50, before_id)
        before_id = tmp.last&.id
        acc += tmp.select { |x| x.author.id == user.id }
        break acc unless before_id
        acc
      end

    messages.take(amount)
  end
end
