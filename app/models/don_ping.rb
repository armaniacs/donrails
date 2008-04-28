require 'uri'
require 'net/http'
require 'xmlrpc/client'

class DonPing < ActiveRecord::Base
  belongs_to :article
#  belongs_to :enrollment

  # send_ping2: send for trackback ping.
  #
  # This format is described at 
  # http://www.sixapart.com/pronet/docs/trackback_spec
  def send_trackback(pingurl, title, excerpt)
    uri = URI.parse(pingurl)
    post = "title=#{URI.escape(title)}"
    post << "&excerpt=#{URI.escape(excerpt)}"
    post << "&url=#{URI.escape(self.url)}"
    post << "&blog_name=#{URI.escape(don_get_config.rdf_title)}"

    Net::HTTP.start(uri.host, uri.port) do |http|
      http.read_timeout = 10
      response = http.post("#{uri.path}?#{uri.query}", post)
      return response.body
    end 
  end

  def send_ping2a(type=nil)
    case type
    when 'extended'
      rbody = send_ping_xmlrpc_extended(self.url)
    when 'xmlrpc'
      rbody = send_ping_xmlrpc(self.url)
    when 'rest'
      rbody_rest = send_ping_rest(self.url)
    else
      rbody = send_ping_xmlrpc_extended(self.url)
      if rbody == true || rbody['flerror'] == true
        rbody = send_ping_xmlrpc(self.url)
        if rbody == true || rbody['flerror'] == true
          rbody_rest = send_ping_rest(self.url)
        end
      end
    end

    if rbody && rbody['flerror'] == false
      return true, rbody
    elsif rbody && (rbody == true || rbody['flerror'] == true)
      return false, rbody
    end

    if rbody_rest && rbody_rest =~ /Thanks for the ping\./i
      return true, rbody_rest
    else
      return false, rbody_rest
    end

    return false, nil

  end

  def send_ping2(pingurl) 
    result = send_ping_xmlrpc_extended(pingurl)
    if result == true || result['flerror'] == true
      result = send_ping_xmlrpc(pingurl)
      if result == true || result['flerror'] == true
        result = send_ping_rest(pingurl)
      end
    end
    return result
  end

  # http://www.weblogs.com/api.html#7
  # REST client
  #
  # name= <Name of Blog> (limited to 1024 characters)
  # url= <URL of Blog> (limited to 255 characters)
  #
  # Optional Parameter:
  # changesURL= <URL of xml, rdf, or atom feed> (limited to 255 characters)
  #
  # Example HTTP GET request:
  # http://rpc.weblogs.com/pingSiteForm?name=InfraBlog&url=http%3A%2F%2Finfrablog.verisignlabs.com 
  def send_ping_rest(pingurl) 
    uri = URI.parse(pingurl)
    baseurl = don_get_config.baseurl.split('/')
    baseurl << 'archives'
    baseurl << 'id'
    
    if self.article.enrollment_id then
      baseurl << self.article.enrollment_id.to_s
    else
      baseurl << self.article.id.to_s
    end
    changeurl = baseurl.join('/')

    post = "name=#{URI.escape(don_get_config.rdf_title)}"
    post << "&url=#{URI.escape(don_get_config.baseurl)}"
    post << "&changesURL=#{URI.escape(changeurl)}"

    Net::HTTP.start(uri.host, uri.port) do |http|
      http.read_timeout = 10
      if uri.query
        response = http.post("#{uri.path}?#{uri.query}", post)
      else
        response = http.post("#{uri.path}", post)
      end
      return response.body
    end 
  end

  def send_ping_xmlrpc(pingurl)
    result = {}
    begin
      baseurl = don_get_config.baseurl.split('/')
      baseurl << 'archives'
      baseurl << 'id'

      if self.article.enrollment_id then
	baseurl << self.article.enrollment_id.to_s
      else
        baseurl << self.article.id.to_s
      end
      changeurl = baseurl.join('/')

      server = XMLRPC::Client.new2(pingurl)
     # p server
      begin
        result = server.call('weblogUpdates.ping', don_get_config.rdf_title, don_get_config.baseurl, changeurl)

      rescue RuntimeError => e
        logger.error(e)
        return false
      rescue XMLRPC::FaultException => e
        logger.error(e)
      end
    rescue Exception => e
      logger.error(e)
    end
    return result
  end

  # http://www.google.com/help/blogsearch/pinging_API.html
  def send_ping_xmlrpc_extended(pingurl)
    result = {}
    begin
      baseurl = don_get_config.baseurl.split('/')
      baseurl << 'archives'
      baseurl << 'id'
      if self.article.enrollment_id 
        baseurl << self.article.enrollment_id.to_s
      else
        baseurl << self.article.id.to_s
      end
      changeurl = baseurl.join('/')
      rdf_recent = don_get_config.baseurl + 'rdf/rdf_recent/feed.xml'

      cas = Array.new
      self.article.categories.each do |ca|
        cas.push(ca.name)
      end
      categories = cas.join('|')

      server = XMLRPC::Client.new2(pingurl)
      begin
        result = server.call('weblogUpdates.extendedPing', don_get_config.rdf_title, don_get_config.baseurl, changeurl, rdf_recent, categories)
      rescue XMLRPC::FaultException => e
        logger.error(e)
      end
    rescue Exception => e
      return true
    end
    return result
  end

end
