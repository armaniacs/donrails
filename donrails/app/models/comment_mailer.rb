class CommentMailer < ActionMailer::Base

#  def notify(comment, commenter, recipient=nil)
  def notify(ct=nil)
    case ct.class.to_s
    when 'Comment'
      comment = ct.body
      commenter = ct.author
      article = ct.article
      cort = 'Comment'
      manage_action = 'manage_comment'
      hidden = ct.hidden
    when 'Trackback'
      comment = ct.excerpt
      commenter = ct.blog_name
      article = ct.article
      cort = 'Trackback'
      manage_action = 'manage_trackback'
      hidden = ct.hidden
    else
      return
    end

    # notify level 0: no notify
    if defined?(don_get_config.notify_level) && don_get_config.notify_level == 0
      return
    end

    # notify level 1: no notify when hidden is '1'.
    if hidden == 1
      if defined?(don_get_config.notify_level) && don_get_config.notify_level <= 1
        return
      end
    end

    if defined?(don_get_config.admin_mailadd) && don_get_config.admin_mailadd
      recipient = don_get_config.admin_mailadd
      from don_get_config.admin_mailadd
    else
      recipient = 'donrails@localhost'
      from 'donrails@localhost'
    end

    if defined?(don_get_config.baseurl) && don_get_config.baseurl
      baseurl = don_get_config.baseurl.split('/')
      url = baseurl.dup
      url << 'archives'
      enrollment_url = url.dup
      url << 'show_title'
      url << article.id.to_s
      enrollment_url << 'show_enrollment'
      enrollment_url << article.enrollment_id.to_s
      login_url = baseurl.dup
      login_url << 'login'
      login_url << manage_action
    else
      url = ['(Please set BASEURL)', 'archives', 'show_title', article.id.to_s]
      enrollment_url = ['(Please set BASEURL)', 'archives', 'show_enrollment', article.id.to_s]
      login_url = ['(Please set BASEURL)', 'login', 'manage_article']
    end

    recipients recipient
    subject "[donrails comment]"
    body :recipient => recipient, :comment => comment, :now => Time.now, :commenter => commenter, :article => article, :url => url.join('/'), :login_url => login_url.join('/'), :cort => cort, :enrollment_url => enrollment_url.join('/'), :hidden => hidden
  end

end
