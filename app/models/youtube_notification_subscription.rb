class YoutubeNotificationSubscription < ActiveRecord::Base
  validates :youtube_channel, presence: true, uniqueness: { scope: :discord_channel }
  validates :discord_channel, presence: true

  belongs_to :youtube_channel
  belongs_to :discord_channel
  has_and_belongs_to_many :youtube_notifications

  def notified?(notification)
    received_notifications.include?(notification)
  end

  def received_notifications
    youtube_notifications
  end

  def youtube_channel_id
    youtube_channel.channel_id
  end

  def discord_channel_id
    discord_channel.cid
  end
end
