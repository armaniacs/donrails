# akismet.rb
# Modified for donrails by ARAKI Yasuhiro <yasu@debian.or.jp>.
# License: BSD
#
# Original file get from 
#    http://rubyforge.org/frs/download.php/14484/akismet.1.2.tar.gz
# Original author and copyrights information as follows.

# Akismet
# Author:: Josh French
# Copyright:: Copyright (c) 2006
# License:: BSD

#require_dependency 'don_env'
require 'net/http'
require 'uri'

require File.dirname(__FILE__) + '/../app/helpers/application_helper'

module Akismet
  include ApplicationHelper

  STANDARD_HEADERS = {
    'User-Agent' => "Rails/#{Rails::VERSION::STRING} | AkismetPlugin/1.0",
    'Content-Type' => 'application/x-www-form-urlencoded'
  }
  
  attr_accessor :verifiedKey, :proxyPort, :proxyHost
  
  def self.included(controller)
    controller.helper_method(:is_spam_by_akismet?, :submit_spam_to_akismet, :submit_ham_to_akismet)
  end

  def initialize
    @verifiedKey = false
    @proxyPort = nil
    @proxyHost = nil

    @akismetBlog = don_get_config.baseurl
    @akismetKey = don_get_config.akismet_key
    super
  end

  # Set proxy information 
  #
  # proxyHost: Hostname for the proxy to use
  # proxyPort: Port for the proxy
  def set_akismet_proxy(proxyHost, proxyPort) 
    @proxyPort = proxyPort
    @proxyHost = proxyHost
  end

  # Call to check and verify your API key. 
  # You may then call the #has_verified_akismet_key? method to see if 
  # your key has been validated.
  def verify_akismet_key()
    http = Net::HTTP.new('rest.akismet.com', 80, @proxyHost, @proxyPort)
    path = '/1.1/verify-key'

    data="key=#{@akismetKey}&blog=#{@akismetBlog}"

    resp, data = http.post(path, data, STANDARD_HEADERS)
    @verifiedKey = (data == "valid")
  end
  
  # Returns true if the API key has been verified, 
  # false otherwise
  def has_verified_akismet_key?()
    return @verifiedKey
  end
  
  # This call takes a hash of arguments about the submitted content and
  # returns a thumbs up or thumbs down. Almost everything is optional, but
  # performance can drop dramatically if you exclude certain elements.
  
  # comment_content: Content to check against Akismet
  #
  # user_ip: IP address of the comment submitter, defaults to request.remote_ip
  #
  # user_agent: User agent information, defaults to request.env['HTTP_USER_AGENT']
  #
  # blog: home URL of instance making this request, defaults to value set above.
  #
  # referrer (note spelling): HTTP_REFERER header, defaults to request.env['HTTP_REFERER']
  #
  # permalink: Permanent location of the entry the comment was submitted to.
  #
  # comment_type: May be blank, comment, trackback, pingback, or 
  #               a made up value like "registration".
  #
  # comment_author: Name submitted with the comment
  #
  # comment_author_email: Email address submitted with the comment
  #
  # comment_author_url: URL submitted with the comment.
  #
  # other: Hash of other server environment variables
  
  def is_spam_by_akismet?(args)
    return call_akismet('comment-check', args)
  end

  # This call is for submitting comments that weren't marked as spam 
  # but should have been. It takes identical arguments as is_spam_by_akismet?
  
  def submit_spam_to_akismet(args)
    call_akismet('submit-spam', args)
  end

  # This call is intended for the marking of false positives, 
  # things that were incorrectly marked as spam. 
  # It takes identical arguments as is_spam_by_akismet? and submit_spam
  
  def submit_ham_to_akismet(args)
    call_akismet('submit-ham', args)
  end
  
  # Internal call to Akismet
  # Prepares the data for posting to the Akismet service.
  #
  # akismet_function: The Akismet function that should be called
  
  def call_akismet(akismet_function, args)
    begin
    args[:blog] ||= @akismetBlog
    args[:user_ip] ||= request.remote_ip
    args[:user_agent] ||= request.env['HTTP_USER_AGENT']
    args[:referrer] ||= request.env['HTTP_REFERER']
    
    http = Net::HTTP.new("#{@akismetKey}.rest.akismet.com", 80, @proxyHost, @proxyPort)
    path = "/1.1/#{akismet_function}"        

    data = args.map { |key,value| "#{key}=#{value}" }.join('&')
    if (args['other'] != nil) 
      args['other'].each_pair {|key, value| data.concat("&#{key}=#{value}")}
    end

    http.open_timeout = 5
    http.read_timeout = 5
    resp, data = http.post(path, data, STANDARD_HEADERS)
    logger.debug resp
    logger.debug data

    return (data != "false")
    rescue
      logger.info '[Akismet]' + $!
      return false
    end
  end
  
  protected :call_akismet
  
end
