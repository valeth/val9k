class CreateServerSettings < ActiveRecord::Migration[5.1]
  def change
    create_table :server_settings do |t|
      t.integer :sid, limit: 8, null: false
      t.text    :key, null: false
      t.json    :value, null: false
    end
  end
end
