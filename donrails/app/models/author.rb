class Author < ActiveRecord::Base
  validates_presence_of :name, :pass
  has_many :articles

  def self.authenticate(name, pass)
    find_first(["name = ? AND pass = ?", name, pass])
  end

  def self.authenticate?(name, pass)
    user = self.authenticate(name, pass)
    return false if user.nil?
    return true if user.name == name

    false
  end

end
