# frozen_string_literal: true

require "benchmark"
require "json"
require_relative "client"
require_relative "constants/benchmark_constants"

client = DatabaseClient.new

def generate_json_data(i)
  { name: "User #{i}", age: rand(18..80), email: "user#{i}@example.com" }.to_json
end

puts "Creating database..."
client.create_database(BenchmarkConstants::DB_NAME, BenchmarkConstants::SEGMENT_SIZE,
                       BenchmarkConstants::FSYNC_FREQUENCY)

puts "\nBenchmarking linear access (sequential insert and read)..."
ids = []
Benchmark.bm(7) do |x|
  x.report("Insert") do
    BenchmarkConstants::NUM_OPERATIONS.times do |i|
      response = client.insert(BenchmarkConstants::DB_NAME, generate_json_data(i))
      ids << response.id if response.success
    end
  end

  x.report("Read") do
    ids.each do |id|
      client.select(BenchmarkConstants::DB_NAME, id)
    end
  end
end

puts "\nBenchmarking random access (random read and update)..."
Benchmark.bm(7) do |x|
  x.report("Read") do
    BenchmarkConstants::NUM_OPERATIONS.times do
      random_id = ids.sample
      client.select(BenchmarkConstants::DB_NAME, random_id)
    end
  end

  x.report("Update") do
    BenchmarkConstants::NUM_OPERATIONS.times do |i|
      random_id = ids.sample
      client.update(BenchmarkConstants::DB_NAME, random_id, generate_json_data(i + BenchmarkConstants::NUM_OPERATIONS))
    end
  end
end

puts "\nCleaning up..."
client.delete_database(BenchmarkConstants::DB_NAME)
puts "Benchmark completed."
