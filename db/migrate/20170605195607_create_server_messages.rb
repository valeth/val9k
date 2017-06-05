class CreateServerMessages < ActiveRecord::Migration[5.1]
  def change
    create_table :server_messages do |t|
      t.integer :sid, limit: 8, null: false
      t.text    :msg_type, null: false
      t.text    :content, null: false
      t.timestamps
    end
  end
end
