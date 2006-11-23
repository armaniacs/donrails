##
## antispam.rb 
##    written by ARAKI Yasuhiro <yasu@debian.or.jp>
##    License: GPL2
##
##    some code derived from "typo"
##

require_dependency 'banlist'
require_dependency 'don_env'
require_dependency 'don_rbl'

class AntiSpam

  def initialize
    @IP_RBL = don_get_ip_rbl if defined?(don_get_ip_rbl)
    @IP_RBL = [ 'niku.2ch.net', 'opm.blitzed.us', 'bsb.empty.us' ] unless defined?(@IP_RBL)
    @HOST_RBL = don_get_host_rbl if defined?(don_get_host_rbl)
    @HOST_RBL = [ 'rbl.bulkfeeds.jp', 'sc.surbl.org', 'bsb.empty.us' ] unless defined?(@HOST_RBL)
    @URL_LIMIT = don_get_config.url_limit if defined?(don_get_config)
    @URL_LIMIT = 5 unless defined?(@URL_LIMIT)
  end

  def is_spam_by_antispam?(args)
    args.each do |name, string|
      if is_spam?(name, string)
        return true
      end
    end
    return false
  end

  def is_spam?(name, string)
    return false if string.nil?
    return false if string == ""

    reason = catch(:hit) do
      if name == :url
        self.scan_uri_format(string)
        self.scan_uri(URI.parse(string).host)
      elsif name == :ipaddr
        self.scan_ipaddr(string)
      elsif name == :ip
        self.scan_ipaddr(string)
      elsif name == :body
        self.scan_text(string)
      elsif name == :blog_name
        self.scan_text(string)
      elsif name == :title
        self.scan_text(string)
      elsif name == :excerpt
        self.scan_text(string)
      elsif name == :author
        self.scan_text(string)
      else
        return false # is not spam!
      end
    end

    if reason
      logger.info("[SP] Hit: #{reason}")
      return true
    end
  end


  def scan_ipaddr_white(ip_address)
    Banlist.find(:all, :conditions => ["format = ? AND white = ?", "ipaddr", 1]).each do |bp|
      if ip_address.match(/#{bp.pattern}/)
        logger.info("[SP] Whitelist: ipaddr #{bp.pattern} matched")
        return true
      end
    end
  end
  protected :scan_ipaddr_white


  def scan_ipaddr(ip_address)
    return false if true == scan_ipaddr_white(ip_address)
    Banlist.find(:all, :conditions => ["format = ?", "ipaddr"]).each do |bp|
      throw :hit, "IPaddress #{bp.pattern} matched" if ip_address.match(/#{bp.pattern}/)
    end
    @IP_RBL.each do |rbl|
      begin
        if IPSocket.getaddress((ip_address.split('.').reverse + [rbl]).join('.')) == "127.0.0.2"
          throw :hit, "#{rbl} positively resolved #{ip_address}"
        end
      rescue SocketError
      end
    end
    return false
  end
  protected :scan_ipaddr

  def scan_uri_format(string)
    string_uri = string.scan(/(http:\/\/[^\s"]+)/m).flatten.to_s
    if string_uri
      linkuri = URI.parse(string_uri)
      if linkuri.path and linkuri.path.length <= 1
        throw :hit, "#{string} does not include valid path"
      end
    end
  end

  def scan_uri(host)
    Banlist.find(:all, :conditions => ["format = ?", "hostname"]).each do |bp|
      throw :hit, "Hostname #{bp.pattern} matched" if host.match(/#{bp.pattern}/)
    end

    @HOST_RBL.each do |rbl|
      begin
        if [
            IPSocket.getaddress([host, rbl].join('.')),
          ].include?("127.0.0.2")
          throw :hit, "#{rbl} positively resolved #{host}"
        end
      rescue SocketError
      end
    end
    return false
  end
  protected :scan_uri

  def scan_text(string)
    # Scan contained URLs
    uri_list = string.scan(/(http:\/\/[^\s"]+)/m).flatten

    # Check for URL count limit    
    if @URL_LIMIT > 0
      throw :hit, "Hard URL Limit hit: #{uri_list.size} > #{@URL_LIMIT}" if uri_list.size > @URL_LIMIT
    end
    
    uri_list.collect { |uri| URI.parse(uri).host rescue nil }.uniq.compact.each do |host|
      scan_uri(host)
    end

    # add banlist match here.
    Banlist.find(:all, :conditions => ["format = ?", "string"]).each do |bp|
      throw :hit, "String #{bp.pattern} matched" if string.match(/#{Regexp.quote(bp.pattern)}/)
    end

    Banlist.find(:all, :conditions => ["format = ?", "regexp"]).each do |bp|
      throw :hit, "Regex #{bp.pattern} matched" if string.match(/#{bp.pattern}/)
    end

    return false
  end
  protected :scan_text


  def logger
    @logger ||= RAILS_DEFAULT_LOGGER || Logger.new(STDOUT)
  end
end

module ActiveRecord
  module Validations
    module ClassMethods
      def validates_antispam(*attr_names)
        configuration = { :message => "blocked by AntiSpam" }
        configuration.update(attr_names.pop) if attr_names.last.is_a?(Hash)

        validates_each(attr_names, configuration) do |record, attr_name, value|
          record.errors.add(attr_name, configuration[:message]) if AntiSpam.new.is_spam?(attr_name, value)
        end
      end

    end
  end
end
