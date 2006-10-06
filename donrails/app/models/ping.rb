require 'uri'
require 'net/http'

class Ping < ActiveRecord::Base
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
    post << "&blog_name=#{URI.escape(RDF_TITLE)}"

    Net::HTTP.start(uri.host, uri.port) do |http|
      http.read_timeout = 10
      response = http.post("#{uri.path}?#{uri.query}", post)
      return response.body
    end 
  end

  def send_ping2(pingurl) # XXX
    rbody0 = send_ping_xmlrpc_extended(pingurl)
    if rbody0 == true || rbody0['flerror'] == true
      rbody = send_ping_xmlrpc(pingurl)
      if rbody == true || rbody['flerror'] == true
        send_ping_rest(pingurl)
      end
    end
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
  def send_ping_rest(pingurl) # XXX
    uri = URI.parse(pingurl)
    
    if self.article.enrollment_id 
      changeurl = BASEURL + 'id/' + self.article.enrollment_id.to_s
    else
      changeurl = BASEURL + 'id/' + self.article.id.to_s
    end

    post = "name=#{URI.escape(RDF_TITLE)}"
    post << "&url=#{URI.escape(BASEURL)}"
    post << "&changesURL=#{URI.escape(changeurl)}"

    Net::HTTP.start(uri.host, uri.port) do |http|
      http.read_timeout = 10
      response = http.post("#{uri.path}?#{uri.query}", post)
      return response.body
    end 
  end

  # require 'xmlrpc/client'
  def send_ping_xmlrpc(pingurl)
    begin
      if self.article.enrollment_id 
        changeurl = BASEURL + 'id/' + self.article.enrollment_id.to_s
      else
        changeurl = BASEURL + 'id/' + self.article.id.to_s
      end

      server = XMLRPC::Client.new2(pingurl)
      begin
        result = server.call('weblogUpdates.ping', RDF_TITLE, BASEURL, changeurl)
#        return server.call('weblogUpdates.ping', RDF_TITLE, BASEURL)
      rescue XMLRPC::FaultException => e
        logger.error(e)
      end
    rescue Exception => e
      logger.error(e)
    end
  end

  # http://www.google.com/help/blogsearch/pinging_API.html
  def send_ping_xmlrpc_extended(pingurl)
    begin
      if self.article.enrollment_id 
        changeurl = BASEURL + 'id/' + self.article.enrollment_id.to_s
      else
        changeurl = BASEURL + 'id/' + self.article.id.to_s
      end
      rdf_recent = BASEURL + 'rdf_recent/feed.xml'

      cas = Array.new
      self.article.categories.each do |ca|
        cas.push(ca.name)
      end
      categories = cas.join('|')

      server = XMLRPC::Client.new2(pingurl)
      begin
        result = server.call('weblogUpdates.extendedPing', RDF_TITLE, BASEURL, changeurl, rdf_recent, categories)
      rescue XMLRPC::FaultException => e
        logger.error(e)
      end
    rescue Exception => e
      logger.error(e)
    end
  end

end
