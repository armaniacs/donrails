class DonAttachment < ActiveRecord::Base
  include ApplicationHelper

  has_and_belongs_to_many :articles, :join_table => "don_attachments_articles"
end
