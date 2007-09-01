require 'test/unit'

ENV["RAILS_ENV"] = "test"
p File.expand_path(File.dirname(__FILE__))
require File.expand_path(File.dirname(__FILE__) + "/../../rails/config/environment")
require 'test_help'
require 'antispam'

class TC_AntiSpam < Test::Unit::TestCase

  def setup
    @obj = AntiSpam.new
  end

  def teardown
  end

  def test_is_spam_nil
    assert_equal(false, @obj.is_spam?(nil,nil))
    assert_equal(false, @obj.is_spam?(nil,""))
  end

  def test_is_spam_url
    assert_not_equal(true, @obj.is_spam?(:url, "http://www.araki.net/new"))
    assert_equal(true, @obj.is_spam?(:url,"http://www.araki.net/"))
  end

  def test_is_spam_ip
    assert_not_equal(true, @obj.is_spam?(:ip, "127.0.0.1"))
    assert_not_equal(true, @obj.is_spam?(:ip, "0.0.0.0"))
    assert_equal(true, @obj.is_spam?(:ip, "127.0.0.2"))
    assert_equal(true, @obj.is_spam?(:ip, "143.238.238.45"))
  end
  alias :test_is_spam_ipaddr :test_is_spam_ip

  def test_is_spam_body
    assert_not_equal(true, @obj.is_spam?(:body, "normal"))
    assert_equal(true, @obj.is_spam?(:body,"sex"))
  end
  alias :test_is_spam_blog_name :test_is_spam_body
  alias :test_is_spam_title :test_is_spam_body
  alias :test_is_spam_excerpt :test_is_spam_body
  alias :test_is_spam_author :test_is_spam_body

end
