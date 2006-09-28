require File.dirname(__FILE__) + '/../test_helper'

require 'rexml/document'
require 'htree'

class PingTest < Test::Unit::TestCase
  fixtures :pings, :articles

  def setup
    @ping = Ping.new
  end

  def test_send_trackback
    @ping1 = Ping.find(1)
    pingurl = "http://localhost:3000/notes/catch_trackback/"
    title = "test title"
    excerpt = "test excerpt"
    rbody = @ping1.send_trackback(pingurl, title, excerpt)
    xml = HTree.parse(rbody).to_rexml
    assert_equal('0', xml.elements['response/error'].text)
  end

  def test_send_ping2
  end

  def test_send_ping_rest
    @ping1 = Ping.find(1)
    pingurl = "http://localhost:3000/notes/catch_ping/"
    rbody = @ping1.send_ping_rest(pingurl)
    xml = HTree.parse(rbody).to_rexml
    assert_equal('0', xml.elements['methodResponse/params/param/value/struct/member/value/boolean'].text)
  end

  def test_send_ping_xmlrpc
    @ping1 = Ping.find(1)
    pingurl = "http://localhost:3000/backend/api"
    rbody = @ping1.send_ping_xmlrpc(pingurl)
    assert_equal(false, rbody['flerror'])
  end

  def test_send_ping2
    @ping1 = Ping.find(1)
    pingurl = "http://localhost:3000/backend/api"
    rbody = @ping1.send_ping_xmlrpc(pingurl)
    assert_equal(false, rbody['flerror'])
  end


  def test_truth
    assert_kind_of Ping,  @ping
  end

end
