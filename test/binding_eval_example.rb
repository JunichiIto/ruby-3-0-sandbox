begin
  # binding.eval('raise "oops"')
  b = binding
  b.eval('raise "oops"', *b.source_location)
rescue => e
  puts e.backtrace
end
