class YoutubeChannel < ActiveRecord::Base
  validates :channel_id, presence: true, uniqueness: true
  validates :name, presence: true

  has_many :youtube_notification_subscriptions, dependent: :destroy
  has_many :youtube_notifications

  def url
    "https://youtube.com/channel/#{channel_id}"
  end

  def notification_subscriptions
    youtube_notification_subscriptions
  end

  def to_s
    "#{name} (#{channel_id})"
  end
end
