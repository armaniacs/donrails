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

    if defined?(ADMIN_MAILADD) && ADMIN_MAILADD
      recipient = ADMIN_MAILADD
      from ADMIN_MAILADD
    else
      recipient = 'donrails@localhost'
      from 'donrails@localhost'
    end

    if defined?(BASEURL) && BASEURL
      url = BASEURL + 'show_title/' + article.id.to_s
      b = BASEURL.split('/')
      b.pop
      login_url = b.join('/') + '/login/manage_article'
    else
      url = '(Please set BASEURL in donrails_env.rb)/' + 'show_title/' + article.id.to_s
      login_url = '(Please set BASEURL in donrails_env.rb)/' + '../login/manage_article'
    end

    recipients recipient
    subject "[donrails comment]"
    body :recipient => recipient, :comment => comment, :now => Time.now, :commenter => commenter, :article => article, :url => url, :login_url => login_url, :cort => cort
  end

end
