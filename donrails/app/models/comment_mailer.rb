class CommentMailer < ActionMailer::Base

  def notify(comment, commenter, recipient=nil)
    unless recipient
      if ADMIN_MAILADD
        recipient = ADMIN_MAILADD
        from ADMIN_MAILADD
      else
        recipient = 'donrails@localhost'
        from 'donrails@localhost'
      end
    end

    recipients recipient
    subject "[donrails comment]"

    body :recipient => recipient, :comment => comment, :now => Time.now, :commenter => commenter
  end

end
