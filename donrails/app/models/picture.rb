class Picture < ActiveRecord::Base
  belongs_to :article
  validates_format_of :content_type, 
  :with => /^image/,
  :message => "--- you can only upload pictures"

  def base_part_of(file_name)
    name = File.basename(file_name)
    name.gsub(/[^\w._-]/, '_')
  end

  def picture=(picture_field)
    self.name = base_part_of(picture_field.original_filename)
    self.content_type = picture_field.content_type.chomp

    t1 = Time.now

    dumpdir = File.expand_path(RAILS_ROOT) + IMAGE_DUMP_PATH + t1.year.to_s + '-' + t1.month.to_s + '-' + t1.day.to_s + '/'
    unless File.directory? dumpdir
      Dir.mkdir dumpdir
    end
    self.path = dumpdir + self.name
    f = File.new(self.path, "w")
    self.size = f.write(picture_field.read)
    f.close
  end

end
