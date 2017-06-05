class ServerCommand < ActiveRecord::Base
  validates :sid, presence: true
  validates :name, presence: true, uniqueness: { scope: :sid }
  validates :content, presence: true
end
