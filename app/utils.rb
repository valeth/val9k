module Utils
  def code_block(text = nil, syntax: nil)
    text = yield if block_given?
    return if text.nil?
    "```#{syntax}\n#{text}\n```"
  end

  def parse_channel_mention(mention)
    /<#(.*)>/.match(mention)&.captures&.first&.to_i
  end

  def mention_channel(channel_id)
    "<##{channel_id}>"
  end
end
