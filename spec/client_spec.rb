# frozen_string_literal: true

require "rspec"
require_relative "../client"

RSpec.describe DatabaseClient do
  let(:client) { DatabaseClient.new }

  let(:stub) { instance_double(Database::DatabaseService::Stub) }

  before do
    allow(Database::DatabaseService::Stub).to receive(:new).and_return(stub)
  end

  describe "#create_database" do
    it "sends a create database request" do
      expect(stub).to receive(:create_database)
        .with(an_instance_of(Database::CreateDatabaseRequest))
        .and_return(Database::CreateDatabaseResponse.new)

      client.create_database("test_db", 100, 5)
    end
  end

  describe "#delete_database" do
    it "sends a delete database request" do
      expect(stub).to receive(:delete_database)
        .with(an_instance_of(Database::DeleteDatabaseRequest))
        .and_return(Database::DeleteDatabaseResponse.new)

      client.delete_database("test_db")
    end
  end

  describe "#insert" do
    it "sends an insert request" do
      expect(stub).to receive(:insert)
        .with(an_instance_of(Database::InsertRequest))
        .and_return(Database::InsertResponse.new)

      client.insert("test_db", '{"name": "John"}')
    end
  end

  describe "#select" do
    it "sends a select request" do
      expect(stub).to receive(:select)
        .with(an_instance_of(Database::SelectRequest))
        .and_return(Database::SelectResponse.new)

      client.select("test_db", "some_id")
    end
  end

  describe "#delete" do
    it "sends a delete request" do
      expect(stub).to receive(:delete)
        .with(an_instance_of(Database::DeleteRequest))
        .and_return(Database::DeleteResponse.new)

      client.delete("test_db", "some_id")
    end
  end

  describe "#update" do
    it "sends an update request" do
      expect(stub).to receive(:update)
        .with(an_instance_of(Database::UpdateRequest))
        .and_return(Database::UpdateResponse.new)

      client.update("test_db", "some_id", '{"name": "John"}')
    end
  end
end
