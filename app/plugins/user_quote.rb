require "utils"

module UserQuote
  extend Discordrb::Commands::CommandContainer
  extend Discordrb::EventContainer
  extend Utils

  options = {
    min_args: 1,
    description: "Manage quotes on this server.",
    usage: "quote [add <quote name> <quote text> | del <quote name> | <quote name>]"
  }
  command :quote, options do |event, *args|
    sid    = event.server.id
    author = event.author.id

    case args.first
    when "add"  then add(sid, author, args[1], args[2..-1].join(" "))
    when "del"  then del(sid, args[1])
    when "list" then list(event)
    when "get"  then get(sid, args[1])
    else             get(sid, args.first)
    end
  end

  message do |event|
    next unless event.content.start_with?(event.bot.prefix * 2)

    qname = event.content[2..-1]
    next if qname.empty?

    qtext = get(event.server.id, qname)
    event.channel.send(qtext || "Quote not found.")
  end

module_function

  def list(event)
    sid = event.server.id
    quotes = Quote.where(sid: sid).order(:created_at)

    if quotes.empty?
      "No quotes on this server"
    else
      code_block(syntax: :ruby) do
        msg = quotes.map do |x|
          user = event.bot.user(x.created_by) || "Unknown User"
          %(:#{x.name} by "#{user.distinct}")
        end

        "# Quotes on this server:\n#{msg.join("\n")}"
      end
    end
  end

  def add(sid, author, qname, qtext)
    begin
      Quote.create! do |m|
        m.name       = qname
        m.content    = qtext
        m.sid        = sid
        m.created_by = author
      end
      "Added quote #{qname}."
    rescue ActiveRecord::RecordInvalid => e
      "Failed to add quote #{qname}: #{e}"
    end
  end

  def del(sid, qname)
    m = Quote.find_by(name: qname)

    if m.nil?
      %(Quote "#{qname}" not found.)
    else
      m.destroy
      %(Quote"#{qname}" deleted.)
    end
  end

  def get(sid, qname)
    Quote.find_by(sid: sid, name: qname)&.content
  end
end
