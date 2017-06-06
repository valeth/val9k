class Quote < ActiveRecord::Base
  validates :sid,        presence: true
  validates :name,       presence: true, uniqueness: { scope: :sid }
  validates :content,    presence: true
  validates :created_by, presence: true
end
