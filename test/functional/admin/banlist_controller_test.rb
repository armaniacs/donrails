require File.dirname(__FILE__) + '/../../test_helper'
require 'admin/banlist_controller'

# Re-raise errors caught by the controller.
class Admin::BanlistController; def rescue_action(e) raise e end; end

class Admin::BanlistControllerTest < ActionController::TestCase
  def setup
    @controller = Admin::BanlistController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  # Replace this with your real tests.
  def test_truth
    assert true
  end

  def test_manage_banlist
    @request.session['person'] = 'ok'
    post :manage_banlist
    assert_response :success
  end

  def test_delete_banlist
    @request.session['person'] = 'ok'
    post :delete_banlist
    assert_redirected_to :action => 'manage_banlist'

    post :delete_banlist, :deleteid => {'1' => '1'}
    assert_redirected_to :action => 'manage_banlist'
  end

  def test_add_banlist
    @request.env["HTTP_REFERER"] = __FILE__
    @request.session['person'] = 'ok'
    post :add_banlist
    assert_response :redirect

    post :add_banlist,
    :banlist => {:add => '1', :pattern => 'test\s+pattern'},
    :banformat => 'regexp'
    assert_response :redirect

    post :add_banlist,
    :banlist => {:add => '1', :pattern => 'test\s+white'},
    :banformat => 'regexp'
    assert_response :redirect

    post :add_banlist,
    :banlist => {:pattern => 'test\s+white'},
    :banformat => 'regexp'
    assert_response :redirect

    post :add_banlist,
    :banlist => {:pattern => 'test\s+black', :teststring => 'test black'},
    :banformat => 'regexp'
    assert_response :redirect
    assert_equal "teststring: \"test black\" is matched pattern: \"test\\s+black\"", flash[:note2]

    post :add_banlist,
    :banlist => {:teststring => 'test black'},
    :banformat => 'regexp'
    assert_response :redirect
    assert_equal "please input", flash[:note2]
  end

  ## issue29
  def test_add_banlist_ipaddr
    @request.env["HTTP_REFERER"] = __FILE__
    @request.session['person'] = 'ok'
    post :add_banlist
    assert_response :redirect

    post :add_banlist,
    :banlist => {:add => '1', :pattern => '123.123.123.123'},
    :banformat => 'ipaddr'
    assert_response :redirect

    post :add_banlist,
    :banlist => {
      "add"=>"0", "white"=>"0", "pattern"=>"127.0.0.1", "teststring"=>"127.0.0.1"},
    :banformat => 'ipaddr'
    assert_response :redirect

    post :add_banlist,
    :commit =>"\343\203\206\343\202\271\343\203\210", 
    :banformat =>"ipaddr", 
    :banlist =>{"add"=>"0", "white"=>"0", "pattern"=>"127.0.0.1", "teststring"=>"127.0.0.1"}
    assert_response :redirect

    post :add_banlist,
    :commit =>"\343\203\206\343\202\271\343\203\210", 
    :banformat =>"ipaddr", 
    :banlist =>{"add"=>"0", "white"=>"0", "pattern"=>"127.0.0.1"}
    assert_response :redirect
  end

  def test_test_banlist
    @request.env["HTTP_REFERER"] = __FILE__
    @request.session['person'] = 'ok'
    post :test_banlist
    assert_response :redirect

    post :test_banlist,
    :banlist => {:pattern => 'test\s+black'}
    assert_response :redirect
  end

end
