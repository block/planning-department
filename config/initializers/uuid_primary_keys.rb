ActiveSupport.on_load(:active_record) do
  require "active_record/connection_adapters/mysql2_adapter"
  ActiveRecord::ConnectionAdapters::Mysql2Adapter::NATIVE_DATABASE_TYPES[:uuid] = { name: "char", limit: 36 }
rescue LoadError
  # Not using MySQL
end
