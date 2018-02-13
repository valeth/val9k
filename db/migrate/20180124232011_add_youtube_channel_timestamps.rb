class AddYoutubeChannelTimestamps < ActiveRecord::Migration[5.1]
  def change
    change_table :youtube_channels do |t|
      t.timestamp :next_update, null: false, default: DateTime.now
      t.timestamps null: false, default: DateTime.now
    end
  end
end
