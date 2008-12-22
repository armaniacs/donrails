require 'kconv'

class Comment < ActiveRecord::Base
  belongs_to :article
  validates_presence_of :author
  validates_length_of :password, :minimum => 4
  validates_length_of :body, :minimum => 5

=begin
  validates_antispam :url
  validates_antispam :ipaddr
  validates_antispam :body
  validates_antispam :author
  validates_antispam :title
=end

  protected
  before_save :kcode_convert, :correct_url, :strip_html_in_body
  after_create :notify_by_mail

  def notify_by_mail
    if defined?(don_get_config.admin_mailadd) && !don_get_config.admin_mailadd.nil? && !don_get_config.admin_mailadd.empty? then
      CommentMailer.deliver_notify(self)
    end
  end

  def kcode_convert
    if body
      self.body = body.toutf8
    end
    if author
      self.author = author.toutf8
    end
    if title
      self.title = title.toutf8
    end
  end

  def correct_url
    unless url.to_s.empty?
      unless url =~ /^http\:\/\//
        self.url = "http://#{url}"
      end
    end
  end

  def strip_html_in_body
    allow = ['p','br','i','b','u','ul','li']
    allow_arr = allow.join('|') << '|\/'
    body.gsub!(/<(\/|\s)*[^(#{allow_arr})][^>]*>/,'')
  end
end
