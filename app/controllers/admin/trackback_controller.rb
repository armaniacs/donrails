class Admin::TrackbackController < AdminController
  cache_sweeper :article_sweeper, :only => [ :delete_trackback ]

  def manage_trackback
    @trackbacks_pages, @trackbacks = paginate(:trackback, :per_page => 30,
                                              :order => 'id DESC')
  end
  def table_trackback_a
    headers["Content-Type"] = "text/html; charset=utf-8"
    @trackbacks_pages, @trackbacks = paginate(:trackback, :per_page => 30,
                                              :order => 'id DESC')
    render :template => 'shared/table_trackback', :layout => false
  end


  def akismet_report
    if params[:id] && params[:sh] == 's' || params[:sh] == 'as' 
      pf = Trackback.find(params[:id])
      aq = {
        :comment_content => pf.excerpt,
        :comment_author_url => pf.url,
        :comment_author => pf.title
      }
      if don_get_config.akismet_key && submit_spam_to_akismet(aq)
        logger.info "[Akismet] Report SPAM"
        pf.update_attribute('spam', 1)
        flash[:note2] = "Report to Akismet: #{pf.id} is SPAM"
      end
      if params[:sh] == 's'
        redirect_to :back
      elsif params[:sh] == 'as'
        if request.env["HTTP_REFERER"] =~ /\/admin\/trackback\/manage_trackback$/
          table_trackback_a
        end
      end
    elsif params[:id] && params[:sh] == 'h' || params[:sh] == 'ah' 
      pf = Trackback.find(params[:id])
      aq = {
        :comment_content => pf.excerpt,
        :comment_author_url => pf.url,
        :comment_author => pf.title
      }
      if don_get_config.akismet_key && submit_ham_to_akismet(aq)
        logger.info "[Akismet] Report HAM"
        pf.update_attribute('spam', 0)
        flash[:note2] = "Report to Akismet: #{pf.id} is HAM"
      end
      if params[:sh] == 'h'
        redirect_to :back
      elsif params[:sh] == 'ah'
        if request.env["HTTP_REFERER"] =~ /\/admin\/trackback\/manage_trackback$/
          table_trackback_a
        end
      end
    end
  end

  def delete_trackback
    flash[:note] = ''
    flash[:note2] = ''
    begin
      if c = params["deleteid"]
        c.each do |k, v|
          if v.to_i == 1
            Trackback.delete(k.to_i)
            flash[:note2] += '<br>Delete:' + k
          end
        end
      end
      if c = params["hideid"]
        c.each do |k, v|
          pf = Trackback.find(k.to_i)
          stmp = pf.hidden
          if v.to_i == 1
            pf.update_attribute('hidden', 1)
          elsif v.to_i == 0
            pf.update_attribute('hidden', 0)
          end
          unless stmp == pf.hidden
            flash[:note2] += '<br>Hyde status:' + k + ' is ' + pf.hidden.to_s
          end
        end
      end
      if c = params["spamid"]
        c.each do |k, v|
          pf = Trackback.find(k.to_i)
          stmp = pf.spam
          if v.to_i == 1
            pf.update_attribute('spam', 1)
          elsif v.to_i == 0
            pf.update_attribute('spam', 0)
          end
          unless stmp == pf.spam
            flash[:note2] += '<br>Spam status:' + k + ' is ' + pf.spam.to_s
          end
        end
      end
    rescue
      @heading = 'fail delete_trackback'
    end
    redirect_to :action => "manage_trackback"
  end

  def delete_hidden_trackback_all
    flash[:note] = ''
    flash[:note2] = ''
    begin
      if params["trigger"] == 'hidden'
        Trackback.delete_all "hidden = 1"
        flash[:note2] += '<br>Delete: ALL hidden trackbacks'
      elsif params["trigger"] == 'spam'
        Trackback.delete_all "spam = 1"
        flash[:note2] += '<br>Delete: ALL spam trackbacks'
      end
    rescue
      @heading = 'fail delete_hidden_trackback_all'
    end
    redirect_to :action => "manage_trackback"
  end

end
