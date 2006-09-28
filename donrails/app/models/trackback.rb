class Trackback < ActiveRecord::Base
  belongs_to :article

  validates_length_of :excerpt, :minimum => 20
  validates_antispam :url
  validates_antispam :ip
  validates_antispam :excerpt
  validates_antispam :blog_name
  validates_antispam :title

  protected
  before_save :kcode_convert
  after_create :notify_by_mail

  validates_each :article do |record, attr, value|
    if value &&
       defined?(TRACKBACK_ENABLE_TIME) &&
       TRACKBACK_ENABLE_TIME != 0 then
      configuration = { :message => "blocked. Because it is a too old article." }
      if value.article_date and value.article_date + TRACKBACK_ENABLE_TIME < Time.now
        record.errors.add(attr, configuration[:message]) 
      end
    end
  end

  def notify_by_mail
    if defined?(ADMIN_MAILADD) && !ADMIN_MAILADD.nil? && !ADMIN_MAILADD.empty? then
      CommentMailer.deliver_notify(self)
    end
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
