class YoutubeNotificationAddThumbnailUrlAndDescription < ActiveRecord::Migration[5.1]
  def change
    change_table :youtube_notifications do |t|
      t.text :thumbnail_url
      t.text :description
    end
  end
end
