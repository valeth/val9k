require "discordrb"

class YoutubeNotification < ActiveRecord::Base
  Embed = Discordrb::Webhooks::Embed
  EmbedAuthor = Discordrb::Webhooks::EmbedAuthor
  EmbedImage = Discordrb::Webhooks::EmbedImage

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
    "https://img.youtube.com/vi/#{video_id}/maxresdefault.jpg"
  end

  def to_embed
    Embed.new(
      title: title,
      url: url,
      author: EmbedAuthor.new(
        name: youtube_channel.name,
        url:  youtube_channel.url
      ),
      image: EmbedImage.new(url: thumbnail_url),
      timestamp: published_at,
      color: 0xfc0c00
    )
  end
end
