# frozen_string_literal: true

require "rspec"
require "json"
require "fileutils"
require_relative "../../lib/database_handler"

RSpec.describe DatabaseHandler do
  let(:db_name) { "test_db" }
  let(:segment_size) { 100 }
  let(:fsync_frequency) { 5 }
  let(:handler) { DatabaseHandler.new(db_name, segment_size, fsync_frequency) }
  let(:file_path) { "#{db_name}.db" }

  after(:each) do
    FileUtils.rm_f(file_path)
  end

  describe "#create_database" do
    it "creates a new database file" do
      expect(handler.create_database).to be true
      expect(File.exist?(file_path)).to be true
    end
  end

  describe "#delete_database" do
    it "deletes the database file" do
      File.write(file_path, "test")
      expect(handler.delete_database).to be true
      expect(File.exist?(file_path)).to be false
    end
  end

  describe "#insert" do
    before { handler.create_database }

    it "inserts valid JSON data" do
      json_data = '{"name": "John", "age": 30}'
      id, success, message = handler.insert(json_data)
      expect(success).to be true
      expect(id).to match(/^id_\d+_\d+$/)
      expect(message).to eq("Data inserted successfully")
    end

    it "rejects data exceeding segment size" do
      large_data = { "name" => "x" * segment_size }.to_json
      _, success, message = handler.insert(large_data)
      expect(success).to be false
      expect(message).to eq("Data size exceeds segment size")
    end

    it "handles invalid JSON" do
      _, success, message = handler.insert("invalid json")
      expect(success).to be false
      expect(message).to eq("Invalid JSON data")
    end
  end

  describe "#select" do
    before do
      handler.create_database
      @inserted_id, = handler.insert('{"name": "John", "age": 30}')
    end

    it "retrieves inserted data" do
      data, success, = handler.select(@inserted_id)
      expect(success).to be true
      expect(JSON.parse(data)).to include("name" => "John", "age" => 30)
    end

    it "returns not found for non-existent id" do
      _, success, message = handler.select("non_existent_id")
      expect(success).to be false
      expect(message).to eq("Data not found")
    end
  end

  describe "#delete" do
    before do
      handler.create_database
      @inserted_id, = handler.insert('{"name": "John", "age": 30}')
    end

    it "deletes existing data" do
      success, message = handler.delete(@inserted_id)
      expect(success).to be true
      expect(message).to eq("Data deleted successfully")

      # Verify data is no longer retrievable
      _, select_success, = handler.select(@inserted_id)
      expect(select_success).to be false
    end

    it "handles non-existent id" do
      success, message = handler.delete("non_existent_id")
      expect(success).to be false
      expect(message).to eq("Data not found")
    end
  end

  describe "#update" do
    before do
      handler.create_database
      @inserted_id, = handler.insert('{"name": "John", "age": 30}')
    end

    it "updates existing data" do
      success, message = handler.update(@inserted_id, '{"name": "John", "age": 31}')
      expect(success).to be true
      expect(message).to eq("Data updated successfully")

      # Verify data was updated
      data, = handler.select(@inserted_id)
      expect(JSON.parse(data)).to include("name" => "John", "age" => 31)
    end

    it "handles non-existent id" do
      success, message = handler.update("non_existent_id", '{"name": "John", "age": 31}')
      expect(success).to be false
      expect(message).to eq("Data not found")
    end

    it "rejects data exceeding segment size" do
      large_data = { "name" => "x" * segment_size }.to_json
      success, message = handler.update(@inserted_id, large_data)
      expect(success).to be false
      expect(message).to eq("Updated data size exceeds segment size")
    end
  end

  describe "concurrency" do
    before { handler.create_database }

    it "handles concurrent inserts without data races" do
      threads = []
      insert_count = 100

      insert_count.times do |i|
        threads << Thread.new do
          json_data = { name: "Test #{i}", value: i }.to_json
          handler.insert(json_data)
        end
      end

      threads.each(&:join)

      # Verify that all inserts were successful
      File.open(file_path, "r") do |file|
        content = file.read
        expect(content.scan(/"name":"Test \d+"/).count).to eq(insert_count)
      end
    end

    it "handles concurrent reads and writes without data races" do
      initial_id, = handler.insert({ name: "Initial", value: 0 }.to_json)

      threads = []
      operation_count = 100

      operation_count.times do |i|
        threads << Thread.new do
          if i.even?
            # Perform a read operation
            handler.select(initial_id)
          else
            # Perform a write operation
            handler.insert({ name: "Test #{i}", value: i }.to_json)
          end
        end
      end

      threads.each(&:join)

      # Verify that all operations were successful
      File.open(file_path, "r") do |file|
        content = file.read
        expect(content.scan(/"name":"Test \d+"/).count).to eq(operation_count / 2)
        expect(content).to include('"name":"Initial"')
      end
    end

    it "handles concurrent updates without data races" do
      initial_id, = handler.insert({ name: "Initial", value: 0 }.to_json)

      threads = []
      update_count = 100

      update_count.times do |i|
        threads << Thread.new do
          handler.update(initial_id, { name: "Updated", value: i }.to_json)
        end
      end

      threads.each(&:join)

      # Verify that the last update was successful
      data, success, = handler.select(initial_id)
      expect(success).to be true
      parsed_data = JSON.parse(data)
      expect(parsed_data["name"]).to eq("Updated")
      expect(parsed_data["value"]).to be >= 0
      expect(parsed_data["value"]).to be < update_count
    end
  end
end
