# frozen_string_literal: true

require 'grpc'
require_relative 'lib/database_pb'
require_relative 'lib/database_services_pb'
require_relative 'lib/database_handler'

$database_configs = {}

class DatabaseService < Database::DatabaseService::Service
  def create_database(request, _call)
    handler = DatabaseHandler.new(request.name, request.segment_size, request.fsync_frequency)
    success = handler.create_database
    if success
      $database_configs[request.name] = {
        segment_size: request.segment_size,
        fsync_frequency: request.fsync_frequency
      }
    end
    Database::CreateDatabaseResponse.new(success: success,
                                         message: success ? 'Database created' : 'Failed to create database')
  end

  def delete_database(request, _call)
    handler = DatabaseHandler.new(request.name, $database_configs[request.name][:segment_size],
                                  $database_configs[request.name][:fsync_frequency])
    success = handler.delete_database
    $database_configs.delete(request.name) if success
    Database::DeleteDatabaseResponse.new(success: success,
                                         message: success ? 'Database deleted' : 'Failed to delete database')
  end

  def insert(request, _call)
    config = $database_configs[request.database_name]
    handler = DatabaseHandler.new(request.database_name, config[:segment_size], config[:fsync_frequency])
    id, success, message = handler.insert(request.json_data)
    Database::InsertResponse.new(id: id, success: success, message: message)
  end

  def select(request, _call)
    config = $database_configs[request.database_name]
    handler = DatabaseHandler.new(request.database_name, config[:segment_size], config[:fsync_frequency])
    json_data, success, message = handler.select(request.id)
    Database::SelectResponse.new(json_data: json_data, success: success, message: message)
  end

  def delete(request, _call)
    config = $database_configs[request.database_name]
    handler = DatabaseHandler.new(request.database_name, config[:segment_size], config[:fsync_frequency])
    success, message = handler.delete(request.id)
    Database::DeleteResponse.new(success: success, message: message)
  end

  def update(request, _call)
    config = $database_configs[request.database_name]
    handler = DatabaseHandler.new(request.database_name, config[:segment_size], config[:fsync_frequency])
    success, message = handler.update(request.id, request.json_data)
    Database::UpdateResponse.new(success: success, message: message)
  end
end

# how for ruby make random seed for rand
# test same seed random (7, 8, 5, 15)
# mock random
# function srand
# head -c 10 /dev/random
# make with uuid
# make with autoincrement
# make id as _id
server = GRPC::RpcServer.new
server.add_http2_port('0.0.0.0:50051', :this_port_is_insecure)
server.handle(DatabaseService)
server.run_till_terminated
