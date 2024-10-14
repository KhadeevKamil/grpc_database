# frozen_string_literal: true

require "grpc"
require "securerandom"
require_relative "lib/database_pb"
require_relative "lib/database_services_pb"
require_relative "lib/database_handler"
require_relative "lib/database_config_manager"

class DatabaseService < Database::DatabaseService::Service
  def create_database(request, _call)
    puts "Creating database: #{request.name}"
    handler = DatabaseHandler.new(request.name, request.segment_size, request.fsync_frequency)
    success = handler.create_database
    DatabaseConfigManager.add_config(request.name, request.segment_size, request.fsync_frequency) if success
    response = Database::CreateDatabaseResponse.new(
      success:,
      message: success ? "Database created" : "Failed to create database"
    )
    puts "Create database response: #{response.success}, #{response.message}"
    response
  end

  def delete_database(request, _call)
    puts "Deleting database: #{request.name}"
    config = DatabaseConfigManager.get_config(request.name)
    unless config
      response = Database::DeleteDatabaseResponse.new(success: false, message: "Database not found")
      puts "Delete database response: #{response.success}, #{response.message}"
      return response
    end

    handler = DatabaseHandler.new(request.name, config[:segment_size], config[:fsync_frequency])
    success = handler.delete_database
    DatabaseConfigManager.remove_config(request.name) if success
    response = Database::DeleteDatabaseResponse.new(
      success:,
      message: success ? "Database deleted" : "Failed to delete database"
    )
    puts "Delete database response: #{response.success}, #{response.message}"
    response
  end

  def insert(request, _call)
    puts "Inserting data into database: #{request.database_name}"
    config = DatabaseConfigManager.get_config(request.database_name)
    unless config
      response = Database::InsertResponse.new(success: false, message: "Database not found")
      puts "Insert response: #{response.success}, #{response.message}"
      return response
    end

    handler = DatabaseHandler.new(request.database_name, config[:segment_size], config[:fsync_frequency])
    id = SecureRandom.uuid
    success, message = handler.insert(id, request.json_data)
    response = Database::InsertResponse.new(id:, success:, message:)
    puts "Insert response: #{response.success}, #{response.message}, ID: #{response.id}"
    response
  end

  def select(request, _call)
    puts "Selecting data from database: #{request.database_name}, ID: #{request.id}"
    config = DatabaseConfigManager.get_config(request.database_name)
    unless config
      response = Database::SelectResponse.new(success: false, message: "Database not found")
      puts "Select response: #{response.success}, #{response.message}"
      return response
    end

    handler = DatabaseHandler.new(request.database_name, config[:segment_size], config[:fsync_frequency])
    results, success, message = handler.select(request.id)
    json_data = results[request.id].to_json if success && results[request.id]
    response = Database::SelectResponse.new(json_data:, success:, message:)
    puts "Select response: #{response.success}, #{response.message}, Data: #{response.json_data}"
    response
  end

  def delete(request, _call)
    puts "Deleting data from database: #{request.database_name}, ID: #{request.id}"
    config = DatabaseConfigManager.get_config(request.database_name)
    unless config
      response = Database::DeleteResponse.new(success: false, message: "Database not found")
      puts "Delete response: #{response.success}, #{response.message}"
      return response
    end

    handler = DatabaseHandler.new(request.database_name, config[:segment_size], config[:fsync_frequency])
    success, message = handler.delete(request.id)
    response = Database::DeleteResponse.new(success:, message:)
    puts "Delete response: #{response.success}, #{response.message}"
    response
  end

  def update(request, _call)
    puts "Updating data in database: #{request.database_name}, ID: #{request.id}"
    config = DatabaseConfigManager.get_config(request.database_name)
    unless config
      response = Database::UpdateResponse.new(success: false, message: "Database not found")
      puts "Update response: #{response.success}, #{response.message}"
      return response
    end

    handler = DatabaseHandler.new(request.database_name, config[:segment_size], config[:fsync_frequency])
    success, message = handler.update(request.id, request.json_data)
    response = Database::UpdateResponse.new(success:, message:)
    puts "Update response: #{response.success}, #{response.message}"
    response
  end
end

server = GRPC::RpcServer.new
server.add_http2_port("0.0.0.0:50051", :this_port_is_insecure)
server.handle(DatabaseService)
server.run_till_terminated
