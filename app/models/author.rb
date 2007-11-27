class Author < ActiveRecord::Base
  validates_presence_of :name, :pass
  has_many :articles

  def self.authenticate(name, pass)
    a = find(:first, :condition => ["name = ? AND pass = ?", name, pass])
    return a
  end

  def self.authenticate?(name, pass)
    user = self.authenticate(name, pass)
    return false if user.nil?
    return true if user.name == name

    false
  end

end
