require 'uri'
require 'net/http'

class Ping < ActiveRecord::Base
  belongs_to :article

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
  def send_ping2(pingurl)
    uri = URI.parse(pingurl)
    
    articleurl = self.url
    rdfurl = articleurl.gsub('/notes/id/', '/notes/rdf_article/')
    up = URI.parse(articleurl).path
    baseurl = articleurl.gsub(up, '/')

    post = "name=#{URI.escape(RDF_TITLE)}"
    post << "&url=#{URI.escape(baseurl)}"
    post << "&changesURL=#{URI.escape(rdfurl)}"

    Net::HTTP.start(uri.host, uri.port) do |http|
      http.read_timeout = 10
      response = http.post("#{uri.path}?#{uri.query}", post)
      return response.body
    end 
  end

end
