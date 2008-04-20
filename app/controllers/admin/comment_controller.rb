class Admin::CommentController < AdminController
  cache_sweeper :article_sweeper, :only => [ :delete_comment ]

  def manage_comment
    @comments = Comment.paginate(:page => params[:page], :per_page => 30,
                                          :order => 'id DESC')
  end


  def delete_hidden_comment_all
    flash[:note] = ''
    flash[:note2] = ''
    begin
      Comment.delete_all "hidden = 1"
      flash[:note2] += '<br>Delete: ALL hidden comments'
    rescue
      @heading = 'fail delete_hidden_comment_all'
    end
    redirect_to :action => "manage_comment"
  end

  def delete_comment
    flash[:note] = ''
    flash[:note2] = ''
    if c = params["deleteid"]
      c.each do |k, v|
        if v.to_i == 1
          begin
            b = Comment.find(k.to_i)
            Comment.delete(k.to_i)
            flash[:note2] += '<br>Delete:' + k
          rescue
          end
        end
      end
    end
    if c = params["hideid"]
      c.each do |k, v|
        begin
          pf = Comment.find(k.to_i)
          stmp = pf.hidden
          if v.to_i == 1
            pf.update_attribute('hidden', 1)
          elsif v.to_i == 0
            pf.update_attribute('hidden', 0)
          end
          unless stmp == pf.hidden
            flash[:note2] += '<br>Hyde status:' + k + ' is ' + pf.hidden.to_s
          end
        rescue
        end
      end
    end
    redirect_to :action => "manage_comment"
  end

end
