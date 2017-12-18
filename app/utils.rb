module Utils
  def code_block(text, syntax: nil)
    text = yield if block_given?

    <<~MSG
            ```#{syntax}
            #{text}
            ```
        MSG
  end

  # String -> Integer|NilClass
  def parse_channel_mention(mention)
    /<#(.*)>/.match(mention)&.captures&.first&.to_i
  end
end
