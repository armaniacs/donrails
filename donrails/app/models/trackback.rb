class Trackback < ActiveRecord::Base
  belongs_to :article

  validates_antispam :url
  validates_antispam :ip
  validates_antispam :excerpt
  validates_antispam :blog_name
  validates_antispam :title

  protected
  before_save :kcode_convert
  after_create :notify_by_mail

  def notify_by_mail
    CommentMailer.deliver_notify(excerpt, blog_name)
  end

  def kcode_convert
    if excerpt
      self.excerpt = excerpt.toutf8
    end
    if blog_name
      self.blog_name = blog_name.toutf8
    end
    if title
      self.title = title.toutf8
    end
  end

end
