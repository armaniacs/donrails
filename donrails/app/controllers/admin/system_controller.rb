class Admin::SystemController < AdminController

  ## ping
  def manage_don_ping
    @don_pings_pages, @don_pings = paginate(:don_ping,:per_page => 30,:order_by => 'id DESC')
  end
  alias manage_ping manage_don_ping

  ## blogping
  def manage_blogping
    if defined?(don_get_config.baseurl)
      flash[:note2] = 'BASEURL is ' + don_get_config.baseurl
    else
      flash[:note2] = '現在Ping送信機能は無効です。baseurlを設定してください。'
    end
    @blogpings_pages, @blogpings = paginate(:blogping,:per_page => 30,:order_by => 'id DESC')
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
    @authors_pages, @authors = paginate(:author, :per_page => 30,
                                          :order_by => 'id DESC'
                                          )
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

      aris1.save
    end
    begin
      don_delete_cache_all
      flash[:note2] = 'cache files and sub-directories are deleted.'
    rescue
      flash[:note2] = $!
    end
    redirect_to :action => "manage_don_env"
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
