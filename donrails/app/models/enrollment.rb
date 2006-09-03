class Enrollment < ActiveRecord::Base
  has_many :articles, :order => "id DESC", :limit => 10
end
