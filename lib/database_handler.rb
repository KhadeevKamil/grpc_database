# frozen_string_literal: true

require "json"
require "fileutils"

class DatabaseHandler
  # save all database config in another config, for correct work on rebut
  # keep array of open database files

  def initialize(db_name, segment_size, fsync_frequency)
    @db_name = db_name
    @segment_size = segment_size
    @fsync_frequency = fsync_frequency
    @file_path = "#{db_name}.db"
    @operation_count = 0
    @mutex = Mutex.new
  end

  def create_database
    @mutex.synchronize do
      File.open(@file_path, "w") {}
    end
    true
  rescue StandardError
    false
  end

  def delete_database
    @mutex.synchronize do
      FileUtils.rm_f(@file_path)
    end
    true
  rescue StandardError
    false
  end

  def insert(json_data)
    data = JSON.parse(json_data)
    # генерировать нормальный айдишник
    id = generate_id
    data["id"] = id

    serialized_data = JSON.generate(data)
    return [nil, false, "Data size exceeds segment size"] if serialized_data.bytesize > @segment_size

    @mutex.synchronize do
      File.open(@file_path, "a") do |file|
        file.write(serialized_data.ljust(@segment_size))
        perform_fsync(file)
      end
    end

    [id, true, "Data inserted successfully"]
  rescue JSON::ParserError
    [nil, false, "Invalid JSON data"]
  rescue StandardError => e
    [nil, false, "Error inserting data: #{e.message}"]
  end

  def select(id)
    @mutex.synchronize do
      File.open(@file_path, "r") do |file|
        # file.seek
        while (segment = file.read(@segment_size))
          data = JSON.parse(segment.strip)
          # отдельный файл с оффсетом, где есть индекс короче который на указывает на место на диске
          # селект принимает один/кучу айдишников
          # задача как можно меньше систем колов использовать
          # слой абстракции кэша,
          # 1. прочитал 5,6,7
          # 2. прочитал 6, отдал из кэша
          # мы это всё настраиваем в базе: аля храним последние 100 записей
          # lru cash - least recently used
          return [data.to_json, true, "Data found"] if data["id"] == id
        end
      end
    end
    [nil, false, "Data not found"]
  rescue StandardError => e
    [nil, false, "Error selecting data: #{e.message}"]
  end

  def delete(id)
    temp_file_path = "#{@db_name}_temp.db"
    deleted = false

    # think about, what to do with empty blocks after deleting
    # maybe save array of empty blocks
    #
    @mutex.synchronize do
      File.open(@file_path, "r") do |file|
        File.open(temp_file_path, "w") do |temp_file|
          while (segment = file.read(@segment_size))
            data = JSON.parse(segment.strip)
            if data["id"] == id
              deleted = true
              temp_file.write(" " * @segment_size)
            else
              temp_file.write(segment)
            end
          end
          perform_fsync(temp_file)
        end
      end

      FileUtils.mv(temp_file_path, @file_path)
    end

    [deleted, deleted ? "Data deleted successfully" : "Data not found"]
  rescue StandardError => e
    [false, "Error deleting data: #{e.message}"]
  end

  def update(id, json_data)
    new_data = JSON.parse(json_data)
    new_data["id"] = id
    serialized_data = JSON.generate(new_data)

    return [false, "Updated data size exceeds segment size"] if serialized_data.bytesize > @segment_size

    updated = false
    @mutex.synchronize do
      File.open(@file_path, "r+") do |file|
        while (segment = file.read(@segment_size))
          data = JSON.parse(segment.strip)
          next unless data["id"] == id

          file.pos -= @segment_size
          file.write(serialized_data.ljust(@segment_size))
          updated = true
          perform_fsync(file)
          break
        end
      end
    end

    [updated, updated ? "Data updated successfully" : "Data not found"]
  rescue JSON::ParserError
    [false, "Invalid JSON data"]
  rescue StandardError => e
    [false, "Error updating data: #{e.message}"]
  end

  private

  def generate_id
    "id_#{Time.now.to_i}_#{rand(1000)}"
  end

  def perform_fsync(file)
    @operation_count += 1
    return unless @operation_count >= @fsync_frequency

    file.fsync
    @operation_count = 0
  end
end
