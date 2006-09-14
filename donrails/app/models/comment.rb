require 'kconv'

class Comment < ActiveRecord::Base
#  has_and_belongs_to_many :articles, :join_table => "comments_articles"
  belongs_to :article
  validates_presence_of :author
  validates_length_of :password, :minimum => 4
  validates_length_of :body, :minimum => 5

  validates_antispam :url
  validates_antispam :ipaddr
  validates_antispam :body
  validates_antispam :author
  validates_antispam :title

  protected
  before_save :kcode_convert, :correct_url, :strip_html_in_body
  after_create :notify_by_mail

  def notify_by_mail
    if defined?(ADMIN_MAILADD) && !ADMIN_MAILADD.nil? && ADMIN_MAILADD.empty? then
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
