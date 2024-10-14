class DatabaseHelper
  def self.build_db_name(db_name)
    "#{db_name}.json"
  end
end