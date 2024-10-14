# frozen_string_literal: true

# Generated by the protocol buffer compiler.  DO NOT EDIT!
# Source: database.proto for package 'database'

require "grpc"
require_relative "database_pb"

module Database
  module DatabaseService
    class Service
      include ::GRPC::GenericService

      self.marshal_class_method = :encode
      self.unmarshal_class_method = :decode
      self.service_name = "database.DatabaseService"

      rpc :CreateDatabase, ::Database::CreateDatabaseRequest, ::Database::CreateDatabaseResponse
      rpc :DeleteDatabase, ::Database::DeleteDatabaseRequest, ::Database::DeleteDatabaseResponse
      rpc :Insert, ::Database::InsertRequest, ::Database::InsertResponse
      rpc :Select, ::Database::SelectRequest, ::Database::SelectResponse
      rpc :Delete, ::Database::DeleteRequest, ::Database::DeleteResponse
      rpc :Update, ::Database::UpdateRequest, ::Database::UpdateResponse
    end

    Stub = Service.rpc_stub_class
  end
end
