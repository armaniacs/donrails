class Trackback < ActiveRecord::Base
  belongs_to :article

  protected
  before_save :kcode_convert
  after_create :notify_by_mail

  validates_each :article do |record, attr, value|
    if value &&
       defined?(don_get_config.trackback_enable_time) &&
       don_get_config.trackback_enable_time != 0 then
      configuration = { :message => "blocked. Because it is a too old article." }
      if value.article_date and value.article_date + don_get_config.trackback_enable_time < Time.now
        record.errors.add(attr, configuration[:message]) 
      end
    end
  end

  def notify_by_mail
    if defined?(don_get_config.admin_mailadd) && !don_get_config.admin_mailadd.nil? && !don_get_config.admin_mailadd.empty? then
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
