class CommentMailer < ActionMailer::Base

#  def notify(comment, commenter, recipient=nil)
  def notify(ct=nil)
    case ct.class.to_s
    when 'Comment'
      comment = ct.body
      commenter = ct.author
      article = ct.article
      cort = 'Comment'
    when 'Trackback'
      comment = ct.excerpt
      commenter = ct.blog_name
      article = ct.article
      cort = 'Trackback'
    else
      return
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
      url << 'notes'
      enrollment_url = url.dup
      url << 'show_title'
      url << article.id.to_s
      enrollment_url << 'show_enrollment'
      enrollment_url << article.enrollment_id.to_s
      login_url = baseurl.dup
      login_url << 'login'
      login_url << 'manage_article'
    else
      url = ['(Please set BASEURL)', 'notes', 'show_title', article.id.to_s]
      enrollment_url = ['(Please set BASEURL)', 'notes', 'show_enrollment', article.id.to_s]
      login_url = ['(Please set BASEURL)', 'login', 'manage_article']
    end

    recipients recipient
    subject "[donrails comment]"
    body :recipient => recipient, :comment => comment, :now => Time.now, :commenter => commenter, :article => article, :url => url.join('/'), :login_url => login_url.join('/'), :cort => cort, :enrollment_url => enrollment_url.join('/')
  end

end
