require File.dirname(__FILE__) + '/../../test_helper'
require 'admin/system_controller'

# Re-raise errors caught by the controller.
class Admin::SystemController; def rescue_action(e) raise e end; end

class Admin::SystemControllerTest < ActionController::TestCase
  def setup
    @controller = Admin::SystemController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  # Replace this with your real tests.
  def test_truth
    assert true
  end


  def test_manage_don_ping
    @request.session['person'] = 'ok'
    post :manage_don_ping
    assert_response :success
  end

  def test_manage_blogping
    @request.session['person'] = 'ok'
    post :manage_blogping
    assert_response :success
  end

  def test_delete_blogping
    @request.session['person'] = 'ok'
    post :delete_blogping
    assert_redirected_to :controller => 'admin/system', :action => 'manage_blogping'

    post :delete_blogping,
    :acid => {'1' => '1'}
    assert_redirected_to :controller => 'admin/system', :action => 'manage_blogping'
    assert_equal '[Activate] http://localhost:3000/backend/api<br>', flash[:note]
    
    post :delete_blogping,
    :acid => {'1' => '0'}
    assert_redirected_to :controller => 'admin/system', :action => 'manage_blogping'
    assert_equal '[Deactivate] http://localhost:3000/backend/api<br>', flash[:note]

    post :delete_blogping,
    :deleteid => {'1' => '1'}
    assert_redirected_to :controller => 'admin/system', :action => 'manage_blogping'
    assert_equal '[Delete] http://localhost:3000/backend/api<br>', flash[:note]

    post :delete_blogping,
    :deleteid => {'1' => '0'}
    assert_redirected_to :controller => 'admin/system', :action => 'manage_blogping'
  end


  def test_add_blogping
    @request.session['person'] = 'ok'
    post :add_blogping
    assert_redirected_to :controller => 'admin/system', :action => 'manage_blogping'

    post :add_blogping,
    :blogping => {:server_url => 'http://example.com/'}
    assert_redirected_to :controller => 'admin/system', :action => 'manage_blogping'
    assert_equal "[Add] http://example.com/<br>", flash[:note]
  end

  def test_manage_author
    @request.session['person'] = 'ok'
    post :manage_author
    assert_response :success

    post :manage_author, :id => 1
    assert_response :success

  end

  def test_delete_unwrite_author
    @request.session['person'] = 'ok'
    post :delete_unwrite_author
    assert_redirected_to :controller => 'admin/system', :action => 'manage_author'

    post :delete_unwrite_author,
    :acid => {'1' => '1'}
    assert_redirected_to :controller => 'admin/system', :action => 'manage_author'

    post :delete_unwrite_author,
    :acid => {'1' => '0'}
    assert_redirected_to :controller => 'admin/system', :action => 'manage_author'

    post :delete_unwrite_author,
    :deleteid => {'1' => '1'}
    assert_redirected_to :controller => 'admin/system', :action => 'manage_author'

    post :delete_unwrite_author,
    :deleteid => {'1' => '0'}
    assert_redirected_to :controller => 'admin/system', :action => 'manage_author'
  end

  def test_add_author
    @request.session['person'] = 'ok'
    post :add_author
    assert_redirected_to :controller => 'admin/system', :action => 'manage_author'

    post :add_author,
    :author => {:name => 'test author', :pass => 'test pass', :summary => 'test summary'}
    assert_redirected_to :controller => 'admin/system', :action => 'manage_author'

    post :add_author,
    :author => {:name => 'araki2', :pass => 'test pass', :summary => 'test summary'}
    assert_redirected_to :controller => 'admin/system', :action => 'manage_author'

  end

end
