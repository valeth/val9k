class ServerSetting < ActiveRecord::Base
  validates :sid, presence: true
  validates :key, presence: true, uniqueness: { scope: :sid }
  validates :value, presence: true
end
