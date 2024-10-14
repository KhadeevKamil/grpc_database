# frozen_string_literal: true

require "grpc"
require_relative "lib/database_services_pb"

class DatabaseClient
  attr_reader :last_inserted_id

  def initialize(host = "localhost:50051")
    @stub = Database::DatabaseService::Stub.new(host, :this_channel_is_insecure)
    @last_inserted_id = nil
  end

  def create_database(name, segment_size, fsync_frequency)
    request = Database::CreateDatabaseRequest.new(name:, segment_size:,
                                                  fsync_frequency:)
    @stub.create_database(request)
  end

  def delete_database(name)
    request = Database::DeleteDatabaseRequest.new(name:)
    @stub.delete_database(request)
  end

  def insert(database_name, json_data)
    request = Database::InsertRequest.new(database_name: database_name, json_data: json_data)
    response = @stub.insert(request)
    @last_inserted_id = response.id if response.success
    response
  end

  def select(database_name, id)
    request = Database::SelectRequest.new(database_name:, id:)
    @stub.select(request)
  end

  def delete(database_name, id)
    request = Database::DeleteRequest.new(database_name:, id:)
    @stub.delete(request)
  end

  def update(database_name, id, json_data)
    request = Database::UpdateRequest.new(database_name:, id:, json_data:)
    @stub.update(request)
  end
end
