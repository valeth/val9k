class DiscordChannel < ActiveRecord::Base
  validates :cid, presence: true
  validates :sid, presence: true
end
