# frozen_string_literal: true

class DatabaseConfigManager
  CONFIG_FILE = "database_configs.json"

  def self.load_configs
    puts "Loading configs from #{CONFIG_FILE}"
    if File.exist?(CONFIG_FILE)
      begin
        configs = JSON.parse(File.read(CONFIG_FILE), symbolize_names: true)
        puts "Loaded configs: #{configs}"
        configs
      rescue JSON::ParserError => e
        puts "Error parsing JSON: #{e.message}"
        {}
      end
    else
      puts "Config file does not exist"
      {}
    end
  end

  def self.save_configs(configs)
    puts "Saving configs: #{configs}"
    File.write(CONFIG_FILE, JSON.pretty_generate(configs))
  end

  def self.add_config(name, segment_size, fsync_frequency)
    puts "Adding config for #{name}"
    configs = load_configs
    configs[name.to_sym] = { segment_size:, fsync_frequency: }
    save_configs(configs)
  end

  def self.remove_config(name)
    puts "Removing config for #{name}"
    configs = load_configs
    configs.delete(name.to_sym)
    save_configs(configs)
  end

  def self.get_config(name)
    puts "Getting config for #{name}"
    configs = load_configs
    config = configs[name.to_sym]
    puts "Config for #{name}: #{config}"
    config
  end
end
