class CreateServerCommands < ActiveRecord::Migration[5.1]
  def change
    create_table :server_commands do |t|
      t.integer :sid, limit: 8, null: false
      t.text    :name, null: false
      t.text    :content, null: false
      t.timestamps
    end
  end
end
