class DonaDaa < ActiveRecord::Base
  belongs_to :article
  belongs_to :don_attachment
  validates_uniqueness_of :article_id, :scope => "don_attachment_id"
end

