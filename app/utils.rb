module Utils
  def code_block(text, syntax: nil)
    text = yield if block_given?

    <<~MSG
            ```#{syntax}
            #{text}
            ```
        MSG
  end
end
