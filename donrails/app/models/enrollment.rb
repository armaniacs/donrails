class Enrollment < ActiveRecord::Base
  has_many :articles, :order => "id DESC" #, :limit => 10
#  has_many :pings, :order => "id ASC"
#  has_many :trackbacks, :order => "id ASC"
#  has_many :pictures, :order => "id ASC"
end
