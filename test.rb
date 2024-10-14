require 'securerandom'

def generate_id
  SecureRandom.uuid
end

1_000_000.times do
  puts generate_id
end