class Category < ActiveRecord::Base
  acts_as_nested_set
  has_many :dona_cas
  has_many :articles, :through => :dona_cas

  validates_format_of :name, :with => /\D+\w*/
end
