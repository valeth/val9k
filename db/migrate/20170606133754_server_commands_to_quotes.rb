class ServerCommandsToQuotes < ActiveRecord::Migration[5.1]
  def change
    rename_table :server_commands, :quotes
    change_table :quotes do |t|
      t.integer :created_by, limit: 8, null: false
    end
  end
end
