class Author < ActiveRecord::Base
  validates_presence_of :name, :pass
  has_many :articles
end
