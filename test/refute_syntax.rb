module RefuteSyntax
  def refute_syntax(script, message = nil, debug: false)
    err = assert_raises(SyntaxError) do
      RubyVM::InstructionSequence.compile(script)
    end
    puts err.message if debug
    if message
      assert_includes err.message, message
    end
  end
end
