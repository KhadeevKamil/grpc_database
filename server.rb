# frozen_string_literal: true

require 'grpc'
require 'securerandom'
require_relative 'lib/database_pb'
require_relative 'lib/database_services_pb'
require_relative 'lib/database_handler'
require_relative 'lib/database_config_manager'

class DatabaseService < Database::DatabaseService::Service
  def create_database(request, _call)
    handler = DatabaseHandler.new(request.name, request.segment_size, request.fsync_frequency)
    success = handler.create_database
    if success
      DatabaseConfigManager.add_config(request.name, request.segment_size, request.fsync_frequency)
    end
    Database::CreateDatabaseResponse.new(success: success,
                                         message: success ? 'Database created' : 'Failed to create database')
  end

  def delete_database(request, _call)
    config = DatabaseConfigManager.load_configs[request.name]
    return Database::DeleteDatabaseResponse.new(success: false, message: 'Database not found') unless config

    handler = DatabaseHandler.new(request.name, config[:segment_size], config[:fsync_frequency])
    success = handler.delete_database
    DatabaseConfigManager.remove_config(request.name) if success
    Database::DeleteDatabaseResponse.new(success: success,
                                         message: success ? 'Database deleted' : 'Failed to delete database')
  end

  def insert(request, _call)
    config = DatabaseConfigManager.load_configs[request.database_name]
    return Database::InsertResponse.new(success: false, message: 'Database not found') unless config

    handler = DatabaseHandler.new(request.database_name, config[:segment_size], config[:fsync_frequency])
    id = SecureRandom.uuid
    success, message = handler.insert(id, request.json_data)
    Database::InsertResponse.new(id: id, success: success, message: message)
  end

  def select(request, _call)
    config = DatabaseConfigManager.load_configs[request.database_name]
    return Database::SelectResponse.new(success: false, message: 'Database not found') unless config

    handler = DatabaseHandler.new(request.database_name, config[:segment_size], config[:fsync_frequency])
    json_data, success, message = handler.select(request.id)
    Database::SelectResponse.new(json_data: json_data, success: success, message: message)
  end

  def delete(request, _call)
    config = DatabaseConfigManager.load_configs[request.database_name]
    return Database::DeleteResponse.new(success: false, message: 'Database not found') unless config

    handler = DatabaseHandler.new(request.database_name, config[:segment_size], config[:fsync_frequency])
    success, message = handler.delete(request.id)
    Database::DeleteResponse.new(success: success, message: message)
  end

  def update(request, _call)
    config = DatabaseConfigManager.load_configs[request.database_name]
    return Database::UpdateResponse.new(success: false, message: 'Database not found') unless config

    handler = DatabaseHandler.new(request.database_name, config[:segment_size], config[:fsync_frequency])
    success, message = handler.update(request.id, request.json_data)
    Database::UpdateResponse.new(success: success, message: message)
  end
end

server = GRPC::RpcServer.new
server.add_http2_port('0.0.0.0:50051', :this_port_is_insecure)
server.handle(DatabaseService)
server.run_till_terminated