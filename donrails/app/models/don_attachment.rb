require 'digest/md5'
require 'fileutils'

class DonAttachment < ActiveRecord::Base
  include ApplicationHelper

  has_and_belongs_to_many :articles, :join_table => "don_attachments_articles"

  def base_part_of(file_name)
    name = File.basename(file_name)
    name.gsub(/[^\w._-]/, '_')
  end

  def don_attachment=(attachment_field)
    don_attachment_assign(attachment_field)
  end

  def filesave(data)
    if data && !date.empty?
      filesave_internal(data)
    end
  end

  private
  def don_attachment_assign(attachment_field, default_format = 'application')
    if self.title.nil? || self.title.empty?
      self.title = base_part_of(attachment_field.original_filename)
    end
    self.content_type = attachment_field.content_type.chomp
    if self.format.nil? || self.format.empty?
      self.format = default_format
    end

    if attachment_field.original_filename &&
        !attachment_field.original_filename.empty?
      filesave_internal(attachment_field.read)
    end
  end

  def filesave_internal(data)
    dirname = filedump_dir
    basename = filedump_name
    filename = File.join(dirname, basename)

    path = File.expand_path(dirname, RAILS_ROOT)
    FileUtils.mkdir_p(path)
    path = File.expand_path(filename, RAILS_ROOT)
    File.open(path, "w") do |o|
      self.size = o.write(data)
    end
    self.path = filename
  end

  def filedump_name
    if /\.\w+$/ =~ self.title
      ext = $&
    else
      ext = ''
    end
    md5 = Digest::MD5.new(self.title)
    md5.update(self.id.to_s)
    md5.hexdigest + ext
  end
  def filedump_dir
    File.join(don_get_config.image_dump_path,
              Time.now.strftime("%Y-%m-%d"))
  end

end
