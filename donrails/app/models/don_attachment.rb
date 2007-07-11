require 'digest/md5'
require 'fileutils'

class DonAttachment < ActiveRecord::Base
  include ApplicationHelper

  has_many :dona_daas
  has_many :articles, :through => :dona_daas

  def base_part_of(file_name)
    name = File.basename(file_name)
    name.gsub(/[^\w._-]/, '_')
  end

  def don_attachment=(attachment_field)
    attachment_assign(attachment_field)
  end

  def attachment_assign(attachment_field, default_format = 'application')
    params = {}
    params['title'] = attachment_field.title rescue nil || base_part_of(attachment_field.original_filename || '')
    params['content_type'] = attachment_field.content_type.chomp
    params['format'] = attachment_field.format rescue nil || default_format
    if attachment_field.original_filename &&
        !attachment_field.original_filename.empty?
      params['original_filename'] = attachment_field.original_filename
      data_io = attachment_field
    else
      data_io = nil
    end
    update_attachment_attributes(params, data_io)
  end

  def filesave(data)
    if data && !data.empty?
      filesave_internal(data)
    end
  end

  def update_attachment_attributes(params, data_io)
    self.title =        params['title']        if params['title']
    self.content_type = params['content_type'] if params['content_type']
    self.format =       params['format']       if params['format']

    if params['join_article_ids']
      params['join_article_ids'].split(/\s+/).each do |article_id|
        join_article = Article.find(article_id)
        self.articles.push_with_attributes(join_article)
      end
    end

    if params['curr_article_ids']
      params['curr_article_ids'].each do |article_id, flag|
        if flag.to_i == 0
          part_article = Article.find(article_id)
          @don_attachment.articles.delete(part_article)
        end
      end
    end

    if data_io
      filesave_internal(data_io.read, params['original_filename'])
    end
  end

  private

  def filesave_internal(data, original_filename = nil)
    save unless self.id # get new-id

    if self.path
      path = File.expand_path(self.path, RAILS_ROOT)
    else
      ext = File.extname(original_filename || self.title)
      md5 = Digest::MD5.new.update(self.title)
      md5.update(self.id.to_s)
      basename = md5.hexdigest + ext
      dirname = File.join(don_get_config.image_dump_path,
                          Time.now.strftime("%Y-%m-%d"))
      filename = File.join(dirname, basename)

      path = File.expand_path(dirname, RAILS_ROOT)
      FileUtils.mkdir_p(path)
      path = File.expand_path(filename, RAILS_ROOT)
    end
    File.open(path, "w") do |o|
      self.size = o.write(data)
    end
    self.path = filename
  end

end
