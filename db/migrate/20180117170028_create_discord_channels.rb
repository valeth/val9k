class CreateDiscordChannels < ActiveRecord::Migration[5.1]
  def change
    create_table :discord_channels do |t|
      t.integer :cid, limit: 8, null: false
      t.integer :sid, limit: 8, null: false
    end
  end
end
