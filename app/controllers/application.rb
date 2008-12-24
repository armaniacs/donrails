# The filters added to this controller will be run for all controllers in the application.
# Likewise will all the methods added be available for all controllers.

require 'time'
require 'digest/sha1'
require 'base64'
require 'stringio'
require 'zlib' 

class ApplicationController < ActionController::Base
  filter_parameter_logging :nz

  # magic for initilization 
  class << self
    include ApplicationHelper
  end
  @@dgc = don_get_config 

  # http://blog.craz8.com/articles/2005/12/07/rails-output-compression
  def compress
    if self.request.env['HTTP_ACCEPT_ENCODING'] and self.request.env['HTTP_ACCEPT_ENCODING'].match(/gzip/)
      if self.response.headers["Content-Transfer-Encoding"] != 'binary'
        begin 
          ostream = StringIO.new
          gz = Zlib::GzipWriter.new(ostream)
          gz.write(self.response.body)
          self.response.body = ostream.string
          self.response.headers['Content-Encoding'] = 'gzip'
        ensure
          gz.close
        end
      end
    end
  end

  def set_charset
    unless headers["Content-Type"]
      headers["Content-Type"] = "text/html; charset=utf-8"
    end
  end

  def get_ymd
    if @ymd
      ymd = @ymd
    elsif params['ymd2']
      ymd = convert_ymd(params['ymd2']) 
    elsif (params["year"] and params["month"] and params["day"])
      ymd = convert_ymd("#{params["year"]}-#{params["month"]}-#{params["day"]}")
    elsif (params["year"] and params["month"])
      ymd = convert_ymd("#{params["year"]}-#{params["month"]}-01")
    end
    @ymd = ymd

    if ymd =~ /(\d\d\d\d)-(\d\d)-(\d\d)/
      t2 = Time.local($1,$2,$3)
      @ymd10a = t2 + 86400 * 10 - 1
      @ymd1a = t2.tomorrow
      @ymd31a = t2.next_month
    end
  end

  def convert_ymd(ymdhash)
    if ymdhash =~ /\d\d\d\d-\d\d-\d\d/
      return ymdhash 
    elsif ymdhash =~ /(\d\d\d\d)-(\d\d?)-(\d\d?)/
      y = $1
      m = $2
      d = $3
    elsif ymdhash =~ /(\d\d\d\d)(\d\d)(\d\d)/
      y = $1
      m = $2
      d = $3
    else
      y = ymdhash['created_on(1i)'] 
      m = ymdhash['created_on(2i)']
      d = ymdhash['created_on(3i)']
    end

    ymd = "#{y}-"
    if m =~ /\d\d/
      ymd += "#{m}-"
    elsif m.to_i < 10
      ymd += "0#{m}-"
    else
      ymd += "#{m}-"
    end
    if d =~ /^0\d$/
      ymd += d
    elsif d.to_i < 10
      ymd += "0#{d}"
    else
      ymd += "#{d}"
    end
    return ymd
  end

  
  def wsse_generate(user, pass)
    created = Time.now.iso8601
    nonce = open("/dev/random").read(20).unpack("H*").first
    pd = Digest::SHA1.digest(nonce + created + pass)
    wsse = "UsernameToken Username=\"#{user}\", PasswordDigest=\"#{Base64.encode64(pd).chomp}\", Created=\"#{created}\", Nonce=\"#{Base64.encode64(nonce).chomp}\""
  end

  def wsse_match(wsse) 
    logger.info(wsse)
    user = ''
    pass = ''
    nonce = ''
    if wsse =~ /UsernameToken Username="(\w+)"/
      user = $1
      aris = Author.find(:first, :conditions => ["name = ?", user])
      return false if aris == nil
      pass = aris.pass
    end
    if wsse =~ /Created="(\S+)"/
      created = $1
    end
    if wsse =~ /PasswordDigest="(\S+)"/
      passdigest = Base64.decode64($1)
    end
    if wsse =~ /Nonce="(\S+)"/
      nonce = Base64.decode64($1)
    end
    pd = Digest::SHA1.digest(nonce + created + pass)
    if pd == passdigest
      @user = user
      return true
    else
      return false
    end
  end

  def clean_memory
    GC.start
  end

  
  def don_delete_cache_all
    logger.info 'Expireing: all page'

    begin
      ppfile = RAILS_ROOT + '/public/index.html'
      File.delete ppfile
      logger.info "Expired page: #{ppfile}"
    rescue
    end
    begin
      ppfile = RAILS_ROOT + '/public/feed.xml'
      File.delete ppfile
      logger.info "Expired page: #{ppfile}"
    rescue
    end
    begin
      ppfile = RAILS_ROOT + '/public/archives.html'
      File.delete ppfile
      logger.info "Expired page: #{ppfile}"
    rescue
    end

    begin
      ppdir = RAILS_ROOT + '/public/archives'
      don_delete_all(ppdir)
      logger.info "Expired page: #{ppdir}"
    rescue
    end

    begin
      ppdir = RAILS_ROOT + '/public/rdf'
      don_delete_all(ppdir)
      logger.info "Expired page: #{ppdir}"
    rescue
    end

    begin
      ppdir = RAILS_ROOT + '/public/atom'
      don_delete_all(ppdir)
      logger.info "Expired page: #{ppdir}"
    rescue
    end
  end

  def don_delete_all(delthem)
    if FileTest.directory?(delthem) then
      Dir.foreach( delthem ) do |file|  
        next if /^\.+$/ =~ file         
        don_delete_all( delthem.sub(/\/+$/,"") + "/" + file )
      end
      Dir.rmdir(delthem) rescue ""      
    else
      File.delete(delthem)              
    end
  end

  def don_is_spam?(args)

    ip = args[:ip] || request.remote_ip
    if AntiSpam.new.scan_ipaddr_white(ip)
      @message = '[Whitelist]: ' + ip
      return false
    end

    begin
    if request.env['skip_akismet'] != true && don_get_config.akismet_key && is_spam_by_akismet?(args)
      logger.info "[Akismet] blocking."
      @catched = false
      @message = 'blocked by Akismet'
    elsif AntiSpam.new.is_spam_by_antispam?(args)
      @catched = false
      @message = 'blocked by AntiSpam'
    end

      if @reasonString != ''
        @message = @reasonString 
        @catched = false
      end

   if @catched == false
      return true
    else
      return false
    end
    rescue Timeout::Error
      logger.info "[Akismet] skipping. (reason: timeout)"
      return false
    end
  end

  protected
  def authorize
    flash.keep
    flash[:note] = ''
    flash[:note2] = ''
    if request.env['PATH_INFO'] 
      flash[:op] = request.env['PATH_INFO'] 
    elsif request.env['REQUEST_URI']
      flash[:op] = request.env['REQUEST_URI']
    end

    unless session["person"] == "ok"
      flash[:pbp] = params
      session = request.session
      redirect_to :controller => 'admin/login', :action => "login_index"
    end
    response.headers["X-donrails"] = "login"
  end

  private
  def collect_category_ids(category, ccs = Array.new)
    ccs.push category.id
    category.direct_children.each do |cc|
      if cc.direct_children
        ccs = collect_category_ids(cc, ccs)
      end
    end
    return ccs
  end
  
end
