# frozen_string_literal: true

require_relative "client"
require_relative "constants/database_constants"

# Usage example
client = DatabaseClient.new

# Create database
response = client.create_database(DatabaseConstants::DB_NAME, DatabaseConstants::SEGMENT_SIZE,
                                  DatabaseConstants::FSYNC_FREQUENCY)
puts "Create database response: #{response.success}, #{response.message}"

# Insert data
json_data = '{"name": "John Doe", "age": 30}'
if json_data.bytesize <= DatabaseConstants::SEGMENT_SIZE
  response = client.insert("test_db", json_data)
  puts "Insert response: #{response.success}, #{response.message}, ID: #{response.id}"
else
  puts "Data size exceeds segment size"
end

# Select data
if response.success
  select_response = client.select("test_db", response.id)
  puts "Select response: #{select_response.success}, #{select_response.message}, Data: #{select_response.json_data}"
end

# Update data
update_json = '{"name": "John Doe", "age": 31}'
update_response = client.update("test_db", response.id, update_json)
puts "Update response: #{update_response.success}, #{update_response.message}"

# Delete data
delete_response = client.delete("test_db", response.id)
puts "Delete response: #{delete_response.success}, #{delete_response.message}"

# Delete database
response = client.delete_database("test_db")
puts "Delete database response: #{response.success}, #{response.message}"
