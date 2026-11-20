ENV["RAILS_ENV"] ||= "test"
abort "Execute a suíte com RAILS_ENV=test." unless ENV["RAILS_ENV"] == "test"
require_relative "../config/environment"

database = ActiveRecord::Base.connection_db_config
unless database.adapter == "sqlite3" && Rails.root.join(database.database) == Rails.root.join("tmp/test.sqlite3")
  abort "Os testes exigem o banco isolado tmp/test.sqlite3."
end

require "rails/test_help"

# O rollback desfaz os registros. Os arquivos de teste precisam de limpeza separada.
upload_root = Dir.mktmpdir("mural-test-", Rails.root.join("tmp"))
ActiveStorage::Blob.services.fetch(:test).root = upload_root
Minitest.after_run { FileUtils.remove_entry(upload_root) }
