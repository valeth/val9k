class DiscordChannel < ActiveRecord::Base
  validates :cid, presence: true
  validates :sid, presence: true

  has_many :youtube_notification_subscriptions, dependent: :destroy
end
