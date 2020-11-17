class A
  def hoge
    fuga
  end

  def fuga
    1/0
  end
end
A.new.hoge

# https://bugs.ruby-lang.org/issues/8661

# Ruby 2.7
# Traceback (most recent call last):
#   3: from stacktrace_example.rb:10:in `<main>'
# 	2: from stacktrace_example.rb:3:in `hoge'
# 	1: from stacktrace_example.rb:7:in `fuga'
# stacktrace_example.rb:7:in `/': divided by 0 (ZeroDivisionError)

# Ruby 3.0
# stacktrace_example.rb:7:in `/': divided by 0 (ZeroDivisionError)
# 	from stacktrace_example.rb:7:in `fuga'
# 	from stacktrace_example.rb:3:in `hoge'
# from stacktrace_example.rb:10:in `<main>'
