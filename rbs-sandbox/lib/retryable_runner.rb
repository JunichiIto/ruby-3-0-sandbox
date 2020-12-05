require 'retryable'

Retryable.retryable(tries: 3) do
  # Do nothing
end
