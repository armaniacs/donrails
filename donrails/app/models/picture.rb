class Picture < DonAttachment
  validates_format_of :content_type, 
  :with => /^image/,
  :message => "--- you can only upload pictures"

  def picture=(picture_field)
    attachment_assign(picture_field, 'picture')
  end
end
