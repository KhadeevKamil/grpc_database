# frozen_string_literal: true

require "rspec"
require_relative "../server"

RSpec.describe DatabaseService do
  let(:service) { DatabaseService.new }
  let(:db_name) { "test_db" }
  let(:segment_size) { 100 }
  let(:fsync_frequency) { 5 }

  before(:each) do
    $database_configs.clear
  end

  after(:each) do
    FileUtils.rm_f("#{db_name}.db")
  end

  describe "#create_database" do
    it "creates a new database" do
      request = Database::CreateDatabaseRequest.new(
        name: db_name,
        segment_size:,
        fsync_frequency:
      )
      response = service.create_database(request, nil)

      expect(response.success).to be true
      expect(response.message).to eq("Database created")
      expect($database_configs[db_name]).to eq({
                                                 segment_size:,
                                                 fsync_frequency:
                                               })
    end
  end

  describe "#delete_database" do
    before do
      service.create_database(
        Database::CreateDatabaseRequest.new(
          name: db_name,
          segment_size:,
          fsync_frequency:
        ),
        nil
      )
    end

    it "deletes an existing database" do
      request = Database::DeleteDatabaseRequest.new(name: db_name)
      response = service.delete_database(request, nil)

      expect(response.success).to be true
      expect(response.message).to eq("Database deleted")
      expect($database_configs[db_name]).to be_nil
    end
  end

  describe "#insert" do
    before do
      service.create_database(
        Database::CreateDatabaseRequest.new(
          name: db_name,
          segment_size:,
          fsync_frequency:
        ),
        nil
      )
    end

    it "inserts data into the database" do
      request = Database::InsertRequest.new(
        database_name: db_name,
        json_data: '{"name": "John", "age": 30}'
      )
      response = service.insert(request, nil)

      expect(response.success).to be true
      expect(response.message).to eq("Data inserted successfully")
      expect(response.id).to match(/^id_\d+_\d+$/)
    end
  end

  describe "#select" do
    let(:inserted_id) { nil }

    before do
      service.create_database(
        Database::CreateDatabaseRequest.new(
          name: db_name,
          segment_size:,
          fsync_frequency:
        ),
        nil
      )
      insert_response = service.insert(
        Database::InsertRequest.new(
          database_name: db_name,
          json_data: '{"name": "John", "age": 30}'
        ),
        nil
      )
      @inserted_id = insert_response.id
    end

    it "selects data from the database" do
      request = Database::SelectRequest.new(
        database_name: db_name,
        id: @inserted_id
      )
      response = service.select(request, nil)

      expect(response.success).to be true
      expect(response.message).to eq("Data found")
      expect(JSON.parse(response.json_data)).to include("name" => "John", "age" => 30)
    end
  end

  describe "#delete" do
    before do
      service.create_database(
        Database::CreateDatabaseRequest.new(
          name: db_name,
          segment_size:,
          fsync_frequency:
        ),
        nil
      )
      insert_response = service.insert(
        Database::InsertRequest.new(
          database_name: db_name,
          json_data: '{"name": "John", "age": 30}'
        ),
        nil
      )
      @inserted_id = insert_response.id
    end

    it "deletes data from the database" do
      request = Database::DeleteRequest.new(
        database_name: db_name,
        id: @inserted_id
      )
      response = service.delete(request, nil)

      expect(response.success).to be true
      expect(response.message).to eq("Data deleted successfully")
    end
  end

  describe "#update" do
    before do
      service.create_database(
        Database::CreateDatabaseRequest.new(
          name: db_name,
          segment_size:,
          fsync_frequency:
        ),
        nil
      )
      insert_response = service.insert(
        Database::InsertRequest.new(
          database_name: db_name,
          json_data: '{"name": "John", "age": 30}'
        ),
        nil
      )
      @inserted_id = insert_response.id
    end

    it "updates data in the database" do
      request = Database::UpdateRequest.new(
        database_name: db_name,
        id: @inserted_id,
        json_data: '{"name": "John", "age": 31}'
      )
      response = service.update(request, nil)

      expect(response.success).to be true
      expect(response.message).to eq("Data updated successfully")

      # Verify the update
      select_response = service.select(
        Database::SelectRequest.new(database_name: db_name, id: @inserted_id),
        nil
      )
      expect(JSON.parse(select_response.json_data)).to include("name" => "John", "age" => 31)
    end
  end
end
