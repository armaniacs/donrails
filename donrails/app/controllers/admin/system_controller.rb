require 'kconv'
class Admin::SystemController < ApplicationController

  include Akismet

  class << self
    include ApplicationHelper
  end
  @@dgc = don_get_config

  before_filter :authorize
  after_filter :compress
  after_filter :clean_memory

  auto_complete_for :author, :name
  auto_complete_for :category, :name

  layout "login", :except => [:login_index, :index]

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

end
