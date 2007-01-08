class DonAttachment < ActiveRecord::Base
  has_and_belongs_to_many :articles, :join_table => "don_attachments_articles"
end
