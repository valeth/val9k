class CreateYoutubeNotifications < ActiveRecord::Migration[5.1]
  def change
    create_table :youtube_channels do |t|
      t.text :channel_id, null: false
      t.text :name
    end

    create_table :youtube_notification_subscriptions do |t|
      t.timestamps
      t.belongs_to :youtube_channel, null: false, index: true
      t.belongs_to :discord_channel, null: false, index: true
    end

    create_table :youtube_notifications do |t|
      t.text       :video_id, null: false
      t.text       :title, null: false
      t.datetime   :published_at, null: false
      t.datetime   :updated_at, null: false
      t.belongs_to :youtube_channel, null: false
    end

    create_join_table :youtube_notifications, :youtube_notification_subscriptions do |t|
      t.belongs_to :youtube_notification, index: false
      t.belongs_to :youtube_notification_subscription, index: false
    end
  end
end
