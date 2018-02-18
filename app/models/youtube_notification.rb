class YoutubeNotification < ActiveRecord::Base
  validates :video_id,     uniqueness: true, presence: true
  validates :title,        presence: true
  validates :published_at, presence: true
  validates :updated_at,   presence: true

  belongs_to :youtube_channel
  has_and_belongs_to_many :youtube_notification_subscriptions

  def url
    "https://www.youtube.com/watch?v=#{video_id}"
  end

  def thumbnail_url
    self["thumbnail_url"] || default_thumbnail_url
  end

private

  def default_thumbnail_url
    "https://i.ytimg.com/vi/#{video_id}/sddefault.jpg"
  end
end
