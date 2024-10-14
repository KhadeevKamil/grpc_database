# frozen_string_literal: true

require 'json'
require 'fileutils'

class DatabaseConfigManager
  CONFIG_FILE = 'database_configs.json'

  def self.load_configs
    if File.exist?(CONFIG_FILE)
      JSON.parse(File.read(CONFIG_FILE), symbolize_names: true)
    else
      {}
    end
  end

  def self.save_configs(configs)
    File.write(CONFIG_FILE, JSON.pretty_generate(configs))
  end

  def self.add_config(name, segment_size, fsync_frequency)
    configs = load_configs
    configs[name] = { segment_size: segment_size, fsync_frequency: fsync_frequency }
    save_configs(configs)
  end

  def self.remove_config(name)
    configs = load_configs
    configs.delete(name)
    save_configs(configs)
  end
end