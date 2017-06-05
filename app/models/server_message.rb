class ServerMessage < ActiveRecord::Base
  validates :sid, presence: true
  validates :msg_type, presence: true, uniqueness: { scope: :sid }
  validates :content, presence: true
end
