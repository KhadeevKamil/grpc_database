# frozen_string_literal: true

require_relative "client"
require_relative "helpers/database_helper"
require_relative "constants/database_constants"

def print_file_content(file_path)
  puts "\nFile content of #{file_path}:"
  File.open(file_path, "rb") do |file|
    puts file.read.inspect
  end
end

# Usage example
client = DatabaseClient.new

# Create database
puts "Creating database..."
response = client.create_database(DatabaseConstants::DB_NAME, DatabaseConstants::SEGMENT_SIZE,
                                  DatabaseConstants::FSYNC_FREQUENCY)
puts "Create database response: #{response.success}, #{response.message}"

# Insert multiple data entries
puts "\nInserting multiple data entries..."
inserted_ids = []
5.times do |i|
  json_data = "{\"name\": \"Person #{i+1}\", \"age\": #{20+i}}"
  if json_data.bytesize <= DatabaseConstants::SEGMENT_SIZE
    response = client.insert(DatabaseConstants::DB_NAME, json_data)
    puts "Insert response #{i+1}: #{response.success}, #{response.message}, ID: #{response.id}"
    inserted_ids << response.id if response.success
  else
    puts "Data size exceeds segment size for entry #{i+1}"
  end
  print_file_content(DatabaseHelper.build_db_name(DatabaseConstants::DB_NAME))
end

# Select all inserted data
# puts "\nSelecting all inserted data..."
# inserted_ids.each do |id|
#   select_response = client.select(DatabaseConstants::DB_NAME, id)
#   puts "Select response for ID #{id}: #{select_response.success}, #{select_response.message}, Data: #{select_response.json_data}"
# end

# Update one entry
# puts "\nUpdating one entry..."
# update_id = inserted_ids[2] if inserted_ids.length >= 3
# if update_id
#   update_json = "{\"name\": \"Updated Person\", \"age\": 50}"
#   update_response = client.update(DatabaseConstants::DB_NAME, update_id, update_json)
#   puts "Update response: #{update_response.success}, #{update_response.message}"
#   print_file_content("#{DatabaseConstants::DB_NAME}.db")
#
#   # Select the updated entry
#   puts "\nSelecting the updated entry..."
#   select_response = client.select(DatabaseConstants::DB_NAME, update_id)
#   puts "Select response for updated ID #{update_id}: #{select_response.success}, #{select_response.message}, Data: #{select_response.json_data}"
# else
#   puts "Not enough entries to update"
# end

# Delete one entry
# puts "\nDeleting one entry..."
# delete_id = inserted_ids.last
# if delete_id
#   delete_response = client.delete(DatabaseConstants::DB_NAME, delete_id)
#   puts "Delete response: #{delete_response.success}, #{delete_response.message}"
#   print_file_content("#{DatabaseConstants::DB_NAME}.db")
#
#   # Try to select the deleted entry
#   puts "\nTrying to select the deleted entry..."
#   select_response = client.select(DatabaseConstants::DB_NAME, delete_id)
#   puts "Select response for deleted ID #{delete_id}: #{select_response.success}, #{select_response.message}, Data: #{select_response.json_data}"
# else
#   puts "No entries to delete"
# end
#
# # Select all remaining entries
# puts "\nSelecting all remaining entries..."
# inserted_ids.each do |id|
#   select_response = client.select(DatabaseConstants::DB_NAME, id)
#   puts "Select response for ID #{id}: #{select_response.success}, #{select_response.message}, Data: #{select_response.json_data}"
# end

# Print final file content
print_file_content("#{DatabaseConstants::DB_NAME}.json")

# # Delete database
# puts "\nDeleting database..."
# response = client.delete_database(DatabaseConstants::DB_NAME)
# puts "Delete database response: #{response.success}, #{response.message}"



select_response = client.select(DatabaseConstants::DB_NAME, "ce55dbcd-a3a0-48cb-9403-1a49ae298c1d")