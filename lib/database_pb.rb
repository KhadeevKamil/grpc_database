# frozen_string_literal: true

# Generated by the protocol buffer compiler.  DO NOT EDIT!
# source: database.proto

require "google/protobuf"

descriptor_data = "\n\x0e\x64\x61tabase.proto\x12\x08\x64\x61tabase\"T\n\x15\x43reateDatabaseRequest\x12\x0c\n\x04name\x18\x01 \x01(\t\x12\x14\n\x0csegment_size\x18\x02 \x01(\x05\x12\x17\n\x0f\x66sync_frequency\x18\x03 \x01(\x05\":\n\x16\x43reateDatabaseResponse\x12\x0f\n\x07success\x18\x01 \x01(\x08\x12\x0f\n\x07message\x18\x02 \x01(\t\"%\n\x15\x44\x65leteDatabaseRequest\x12\x0c\n\x04name\x18\x01 \x01(\t\":\n\x16\x44\x65leteDatabaseResponse\x12\x0f\n\x07success\x18\x01 \x01(\x08\x12\x0f\n\x07message\x18\x02 \x01(\t\"9\n\rInsertRequest\x12\x15\n\rdatabase_name\x18\x01 \x01(\t\x12\x11\n\tjson_data\x18\x02 \x01(\t\">\n\x0eInsertResponse\x12\n\n\x02id\x18\x01 \x01(\t\x12\x0f\n\x07success\x18\x02 \x01(\x08\x12\x0f\n\x07message\x18\x03 \x01(\t\"2\n\rSelectRequest\x12\x15\n\rdatabase_name\x18\x01 \x01(\t\x12\n\n\x02id\x18\x02 \x01(\t\"E\n\x0eSelectResponse\x12\x11\n\tjson_data\x18\x01 \x01(\t\x12\x0f\n\x07success\x18\x02 \x01(\x08\x12\x0f\n\x07message\x18\x03 \x01(\t\"2\n\rDeleteRequest\x12\x15\n\rdatabase_name\x18\x01 \x01(\t\x12\n\n\x02id\x18\x02 \x01(\t\"2\n\x0e\x44\x65leteResponse\x12\x0f\n\x07success\x18\x01 \x01(\x08\x12\x0f\n\x07message\x18\x02 \x01(\t\"E\n\rUpdateRequest\x12\x15\n\rdatabase_name\x18\x01 \x01(\t\x12\n\n\x02id\x18\x02 \x01(\t\x12\x11\n\tjson_data\x18\x03 \x01(\t\"2\n\x0eUpdateResponse\x12\x0f\n\x07success\x18\x01 \x01(\x08\x12\x0f\n\x07message\x18\x02 \x01(\t2\xbb\x03\n\x0f\x44\x61tabaseService\x12U\n\x0e\x43reateDatabase\x12\x1f.database.CreateDatabaseRequest\x1a .database.CreateDatabaseResponse\"\x00\x12U\n\x0e\x44\x65leteDatabase\x12\x1f.database.DeleteDatabaseRequest\x1a .database.DeleteDatabaseResponse\"\x00\x12=\n\x06Insert\x12\x17.database.InsertRequest\x1a\x18.database.InsertResponse\"\x00\x12=\n\x06Select\x12\x17.database.SelectRequest\x1a\x18.database.SelectResponse\"\x00\x12=\n\x06\x44\x65lete\x12\x17.database.DeleteRequest\x1a\x18.database.DeleteResponse\"\x00\x12=\n\x06Update\x12\x17.database.UpdateRequest\x1a\x18.database.UpdateResponse\"\x00\x62\x06proto3"

pool = Google::Protobuf::DescriptorPool.generated_pool
pool.add_serialized_file(descriptor_data)

module Database
  CreateDatabaseRequest = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("database.CreateDatabaseRequest").msgclass
  CreateDatabaseResponse = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("database.CreateDatabaseResponse").msgclass
  DeleteDatabaseRequest = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("database.DeleteDatabaseRequest").msgclass
  DeleteDatabaseResponse = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("database.DeleteDatabaseResponse").msgclass
  InsertRequest = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("database.InsertRequest").msgclass
  InsertResponse = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("database.InsertResponse").msgclass
  SelectRequest = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("database.SelectRequest").msgclass
  SelectResponse = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("database.SelectResponse").msgclass
  DeleteRequest = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("database.DeleteRequest").msgclass
  DeleteResponse = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("database.DeleteResponse").msgclass
  UpdateRequest = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("database.UpdateRequest").msgclass
  UpdateResponse = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("database.UpdateResponse").msgclass
end
