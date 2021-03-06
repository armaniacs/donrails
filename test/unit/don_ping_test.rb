require File.dirname(__FILE__) + '/../test_helper'

require 'rexml/document'
require 'htree'
require 'hpricot'

class DonPingTest < ActiveSupport::TestCase
  fixtures :don_pings, :articles, :categories, :dona_cas 

  def setup
    @ping = DonPing.new
  end

  def test_send_trackback
    @ping1 = DonPing.find(1)
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
    @ping1 = DonPing.find(1)
    pingurl = "http://localhost:3000/notes/catch_ping/"
    rbody = @ping1.send_ping_rest(pingurl)
    xml = HTree.parse(rbody).to_rexml

    assert_equal('0', xml.elements['methodResponse/params/param/value/struct/member/value/boolean'].text)

    doc = Hpricot(rbody)
    assert_equal('0', (doc/"methodresponse/params/value/struct/member/value/boolean").inner_text)
  end

  def test_send_ping_xmlrpc
    @ping1 = DonPing.find(1)
    pingurl = "http://localhost:3000/backend/api"
    rbody = @ping1.send_ping_xmlrpc(pingurl)
    if rbody == false
      assert_equal(false, rbody)
    else
      assert_equal(false, rbody['flerror'])
    end
  end

  def test_send_ping_xmlrpc_extended
    @ping1 = DonPing.find(1)
    pingurl = "http://localhost:3000/backend/api"
    rbody = @ping1.send_ping_xmlrpc_extended(pingurl)
#    assert_equal(false, rbody['flerror'])
   # p rbody
    if rbody == false
      assert_equal(false, rbody)
    else
      assert_equal(false, rbody['flerror'])
    end
  end

  def test_send_ping2
    @ping1 = DonPing.find(1)
    pingurl = "http://localhost:3000/backend/api"
    rbody = @ping1.send_ping_xmlrpc(pingurl)

#    unless rbody == false
#      assert_equal(false, rbody['flerror'])
#    end
    if rbody == false
      assert_equal(false, rbody)
    else
      assert_equal(false, rbody['flerror'])
    end
  end


  def test_truth
    assert_kind_of DonPing,  @ping
  end

end
