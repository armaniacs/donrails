# -*- coding: utf-8 -*-
class Admin::SystemController < AdminController
  layout 'login', :except => [:pick_donping_a]

  ## ping
  def manage_don_ping
    if params[:on] && params[:on] =~ /^(counter|id|article_id|url|created_at|send_at|status|response_body)$/
      @don_pings = DonPing.paginate(:page => params[:page],:per_page => 30, :order => "#{params[:on]}, id DESC")
    elsif params[:od] && params[:od] =~ /^(counter|id|article_id|url|created_at|send_at|status|response_body)$/
      @don_pings = DonPing.paginate(:page => params[:page],:per_page => 30, :order => "#{params[:od]} DESC, id DESC")
    else
      @don_pings = DonPing.paginate(:page => params[:page],:per_page => 30,:order => 'id DESC')
    end
  end
  alias manage_ping manage_don_ping

  def pick_donping_a
    @don_ping = DonPing.find(params[:id])
  end

  def delete_ping_queue
    c = params["deleteid"].nil? ? [] : params["deleteid"]
    c.each do |k, v|
      if v.to_i == 1
        flash[:note2] = 'Ping Queue ' + k.to_s + ' is deleted. <br>'
        DonPing.destroy(k.to_i)
      end
    end
    redirect_to :back
  end

  ## blogping
  def manage_blogping
    if defined?(don_get_config.baseurl) && don_get_config.baseurl.size >= 10
      flash[:note2] = 'BASEURL is ' + don_get_config.baseurl
    else
      flash[:note2] = '現在Ping送信機能は無効です。<a href="/admin/system/manage_don_env/">baseurlを設定</a>してください。'
    end
    @blogpings = Blogping.paginate(:page => params[:page],:per_page => 30,:order => 'id DESC')
  end

  def delete_blogping
    c = params["acid"].nil? ? [] : params["acid"]
    flash[:note] = ''
    c.each do |k, v|
      b = Blogping.find(k.to_i)
      unless v.to_i == b.active
        b.active = v.to_i
        b.save
        if b.active == 1
          flash[:note] += '[Activate] ' + b.server_url + '<br>'
        else
          flash[:note] += '[Deactivate] ' + b.server_url + '<br>'
        end
      end
    end

    c = params["deleteid"].nil? ? [] : params["deleteid"]
    c.each do |k, v|
      if v.to_i == 1
        b = Blogping.find(k.to_i)
        flash[:note] += '[Delete] ' + b.server_url + '<br>'
        b.destroy
      end
    end
    redirect_to :action => "manage_blogping"
  end

  def add_blogping
    if c = params["blogping"]
      aris1 = Blogping.new("server_url" => c["server_url"])
      aris1.active = 1
      aris1.save
      flash[:note] = '[Add] ' + aris1.server_url + '<br>'
    end
    redirect_to :action => "manage_blogping"
  end


  # author
  def manage_author
    if params['id']
      @author = Author.find(params['id'])
    end
    @authors = Author.paginate(:page => params[:page], :per_page => 30,
                                          :order => 'id DESC')
    if params[:notice]
      flash["notice"] = params[:notice]
    end
  end

  def delete_unwrite_author
    c = params["unwriteid"].nil? ? [] : params["unwriteid"]
    c.each do |k, v|
      if v.to_i == 1
        b = Author.find(k.to_i)
        if b.writable == 1
          b.writable = 0
          b.save
        else
          b.writable = 1
          b.save          
        end
      end
    end
    c = params["deleteid"].nil? ? [] : params["deleteid"]
    c.each do |k, v|
      if v.to_i == 1
        b = Author.find(k.to_i)
        b.destroy
      end
    end
    redirect_to :action => "manage_author"
  end

  def add_author
    if c = params["author"]
      aris1 = Author.find(:first, :conditions => ["name = ?", c["name"]])
      unless aris1
        aris1 = Author.new("name" => c["name"])
      end
      aris1.pass = c["pass"]
      aris1.nickname = c["nickname"]
      aris1.summary = c["summary"]
      aris1.writable = 1
      aris1.save
    end
    redirect_to :action => "manage_author"
  end

  def delete_cache
    begin
      don_delete_cache_all
      flash[:note2] = 'cache files and sub-directories are deleted.'
    rescue
      flash[:note2] = $!
    end
    redirect_to :action => "manage_cache"
  end


  def bm
    @dgc = @@dgc
    if params['f'] == 'add' && params['url'] && params['title']
      @b_url = params['url']
      @b_title = params['title']
      @b_text = params['text'] if params['text']
      render :controller => 'admin/article', :action => 'new_article'
    else
      render :text => 'Please check your bookmarklet setting'
      return
    end
  end

  def manage_don_env
    if params['id']
      @donenv = DonEnv.find(params['id'])
    else
      @donenv = DonEnv.find(:first, :conditions => ["hidden IS NULL OR hidden = 0"])
    end
    @don_envs = DonEnv.find(:all)
  end

  def add_don_env
    if c = params["donenv"]
      if c['id'] && c['id'].size > 0
        aris1 = DonEnv.find(c['id'].to_i)
      else
        aris1 = DonEnv.new
      end
      aris1.image_dump_path = c["image_dump_path"]
      aris1.admin_user = c["admin_user"]
      aris1.admin_password = c["admin_password"]
      aris1.admin_mailadd = c["admin_mailadd"]
      aris1.rdf_title = c["rdf_title"]
      aris1.rdf_description = c["rdf_description"]
      aris1.rdf_copyright = c["rdf_copyright"]
      aris1.rdf_managingeditor = c["rdf_managingeditor"]
      aris1.rdf_webmaster = c["rdf_webmaster"]
      aris1.baseurl = c["baseurl"]
      aris1.url_limit = c["url_limit"]
      aris1.default_theme = c["default_theme"]
      aris1.trackback_enable_time = c["trackback_enable_time"].to_i
      aris1.akismet_key = c["akismet_key"]
      aris1.notify_level = c["notify_level"].to_i
      aris1.ping_async = c["ping_async"].to_i
      aris1.add_clips_id = c["add_clips_id"]
      aris1.default_format = c["default_format"]

      aris1.save
    end
    begin
      don_delete_cache_all
      flash[:note2] = 'cache files and sub-directories are deleted.'
    rescue
      flash[:note2] = $!
    end
    redirect_to :action => "manage_don_env"
##    redirect_to :controller => 'admin/system', :action => 'manage_don_env' 
  end

  def delete_don_env
    flash[:note] = ''
    flash[:note2] = ''
    c = params["deleteid"].nil? ? [] : params["deleteid"]
    c.each do |k, v|
      if v.to_i == 1
        if DonEnv.exists?(k.to_i)
          b = DonEnv.find(k.to_i)
          flash[:note2] += '<br>Delete:' + k
          b.destroy
        else
          flash[:note2] += '<br>Not exists:' + k
        end
      end
    end
    if c = params["hideid"]
      c.each do |k, v|
        if DonEnv.exists?(k.to_i)
          pf = DonEnv.find(k.to_i)
          stmp = pf.hidden
          if v.to_i == 1 and pf.hidden != 1
            pf.update_attribute('hidden', 1)
          elsif v.to_i == 0 and pf.hidden != 0
            pf.update_attribute('hidden', 0)
          end
          unless stmp == pf.hidden
            flash[:note2] += '<br>Hyde status:' + k + ' is ' + pf.hidden.to_s
          end
        else
          flash[:note2] += '<br>Not exists:' + k
        end
      end
    end

    begin
      don_delete_cache_all
      flash[:note2] = 'cache files and sub-directories are deleted.'
    rescue
      flash[:note2] = $!
    end

    redirect_to :action => "manage_don_env"
##    redirect_to :controller => 'admin/system', :action => 'manage_don_env'
  end

  # RBL
  def manage_don_rbl
    @don_rbls = DonRbl.find(:all)
  end

  def add_don_rbl
    if c = params["donrbl"]
      if c['id'] && c['id'].size > 0
        aris1 = DonRbl.find(c['id'].to_i)
      else
        aris1 = DonRbl.new
      end
      aris1.rbl_type = params["format"]
      aris1.hostname = c["hostname"]
      aris1.save
    end
    redirect_to :action => "manage_don_rbl"
  end

  def delete_don_rbl
    flash[:note] = ''
    flash[:note2] = ''
    c = params["deleteid"].nil? ? [] : params["deleteid"]
    c.each do |k, v|
      if v.to_i == 1
        if DonRbl.exists?(k.to_i)
          b = DonRbl.find(k.to_i)
          flash[:note2] += '<br>Delete:' + k
          b.destroy
        else
          flash[:note2] += '<br>Not exists:' + k
        end
      end
    end
    if c = params["hideid"]
      c.each do |k, v|
        if DonRbl.exists?(k.to_i)
          pf = DonRbl.find(k.to_i)
          stmp = pf.hidden
          if v.to_i == 1 and pf.hidden != 1
            pf.update_attribute('hidden', 1)
          elsif v.to_i == 0 and pf.hidden != 0
            pf.update_attribute('hidden', 0)
          end
          unless stmp == pf.hidden
            flash[:note2] += '<br>Hyde status:' + k + ' is ' + pf.hidden.to_s
          end
        else
          flash[:note2] += '<br>Not exists:' + k
        end
      end
    end
    redirect_to :action => "manage_don_rbl"
  end

end
