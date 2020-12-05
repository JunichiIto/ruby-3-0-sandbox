require 'date'
require 'retryable'
require_relative '../lib/fizz_buzz'

Retryable.retryable(tries: 3) do
  results = FizzBuzz.run(Date.today.day)
  puts results
end
