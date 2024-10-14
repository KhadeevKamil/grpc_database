# frozen_string_literal: true

require "json"
require "fileutils"
require "lru_redux"

class DatabaseHandler
  def initialize(db_name, segment_size, fsync_frequency, cache_size = 100)
    @db_name = db_name
    @segment_size = segment_size
    @fsync_frequency = fsync_frequency
    @file_path = "#{db_name}.json"
    @index_path = "#{db_name}.index"
    @operation_count = 0
    @mutex = Mutex.new
    @cache = LruRedux::Cache.new(cache_size)
    @index = load_index
  end

  def create_database
    @mutex.synchronize do
      File.open(@file_path, "w") {}
      File.open(@index_path, "w") {}
    end
    @index = {}
    true
  rescue StandardError
    false
  end

  def delete_database
    @mutex.synchronize do
      FileUtils.rm_f(@file_path)
      FileUtils.rm_f(@index_path)
    end
    @index = {}
    true
  rescue StandardError
    false
  end

  def insert(id, json_data)
    puts "Starting insert operation for id: #{id}"
    data = JSON.parse(json_data)
    data["_id"] = id

    serialized_data = JSON.generate(data)
    puts "Serialized data size: #{serialized_data.bytesize} bytes"
    if serialized_data.bytesize > @segment_size - 1
      puts "Data size exceeds segment size (#{@segment_size - 1} bytes)"
      return [false, "Data size exceeds segment size"]
    end

    @mutex.synchronize do
      puts "Current file size before insert: #{File.size(@file_path)} bytes"
      offset = File.size(@file_path)
      puts "New record will be inserted at offset: #{offset}"

      File.open(@file_path, "r+") do |file|
        puts "File position start: #{file.pos}"
        puts "IO::SEEK_END #{IO::SEEK_END}"
        file.seek(0, IO::SEEK_END)
        puts "File position after seek: #{file.pos}"
        data_block = serialized_data.ljust(@segment_size - 1) + "\n"
        bytes_written = file.write(data_block)
        puts "File position end: #{file.pos}"
        puts "Bytes written to file: #{bytes_written}"
        perform_fsync(file)
      end

      @index[id] = offset
      puts "Updated index: #{@index}"
      save_index
      puts "Index saved"

      puts "New file size after insert: #{File.size(@file_path)} bytes"
    end

    @cache[id] = data
    puts "Data added to cache"

    [true, "Data inserted successfully"]
  rescue JSON::ParserError => e
    puts "JSON parse error: #{e.message}"
    [false, "Invalid JSON data"]
  rescue StandardError => e
    puts "Error during insert: #{e.message}"
    puts e.backtrace.join("\n")
    [false, "Error inserting data: #{e.message}"]
  end

  # Todo make normal select with offset
  def select(*ids)
    puts "Starting select operation for ids: #{ids}"
    results = {}
    not_found = []

    ids.each do |id|
      if @cache.key?(id)
        puts "Data for id #{id} found in cache"
        results[id] = @cache[id]
      else
        puts "Data for id #{id} not found in cache"
        not_found << id
      end
    end

    unless not_found.empty?
      @mutex.synchronize do
        puts "Current index: #{@index}"
        File.open(@file_path, "rb") do |file|
          not_found.each do |id|
            if @index.key?(id)
              offset = @index[id]
              puts "Seeking to offset #{offset} for id #{id}"
              file.seek(offset)
              segment = file.read(@segment_size + 1)

              # TODO clean up segment
              # if segment[-1] != "\n"
              #   true
              # end

              puts "Read #{segment.bytesize} bytes from file"
              data = JSON.parse(segment.strip)
              # TODO тут тоже надо ловить
              puts "Parsed data for id #{id}: #{data}"
              results[id] = data
              @cache[id] = data
            else
              puts "No index entry found for id #{id}"
            end
          end
        end
      end
    end

    not_found_ids = ids - results.keys
    [results, not_found_ids.empty?, not_found_ids.empty? ? "Data found" : "Some data not found"]
  rescue StandardError => e
    puts "Error during select: #{e.message}"
    puts e.backtrace.join("\n")
    [nil, false, "Error selecting data: #{e.message}"]
  end

  def delete(id)
    deleted = false
    @mutex.synchronize do
      if @index.key?(id)
        File.open(@file_path, "r+b") do |file|
          file.seek(@index[id])
          file.write("\0" * @segment_size)
          perform_fsync(file)
        end
        @index.delete(id)
        save_index
        @cache.delete(id)
        deleted = true
      end
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
      if @index.key?(id)
        File.open(@file_path, "r+b") do |file|
          file.seek(@index[id])
          file.write(serialized_data.ljust(@segment_size))
          perform_fsync(file)
        end
        @cache[id] = new_data  # Изменено с @cache.set на @cache[]=
        updated = true
      else
        # Если запись не найдена в индексе, выполняем вставку
        offset = File.size(@file_path)
        File.open(@file_path, "ab") do |file|
          file.write(serialized_data.ljust(@segment_size))
          perform_fsync(file)
        end
        @index[id] = offset
        save_index
        @cache[id] = new_data  # Изменено с @cache.set на @cache[]=
        updated = true
      end
    end

    [updated, updated ? "Data updated successfully" : "Data not found"]
  rescue JSON::ParserError
    [false, "Invalid JSON data"]
  rescue StandardError => e
    [false, "Error updating data: #{e.message}"]
  end

  private

  def perform_fsync(file)
    @operation_count += 1
    return unless @operation_count >= @fsync_frequency

    file.fsync
    @operation_count = 0
  end

  def load_index
    index = {}
    if File.exist?(@index_path)
      File.open(@index_path, "r") do |file|
        file.each_line do |line|
          id, offset = line.strip.split(",")
          index[id] = offset.to_i
        end
      end
    end
    puts "Loaded index: #{index}"
    index
  end

  def save_index
    File.open(@index_path, "w") do |file|
      @index.each do |id, offset|
        file.puts("#{id},#{offset}")
      end
      perform_fsync(file)
    end
    puts "Saved index: #{@index}"
  end
end