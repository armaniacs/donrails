class Category < ActiveRecord::Base
#  acts_as_tree :order => "name"
  acts_as_nested_set ## prepare for change from acts_as_tree.
                      ## because acts_as_tree use huge resources.
  has_and_belongs_to_many :articles, :join_table => "categories_articles"
end
