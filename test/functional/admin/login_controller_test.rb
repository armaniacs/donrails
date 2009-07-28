require File.dirname(__FILE__) + '/../../test_helper'
require 'admin/login_controller'

# Re-raise errors caught by the controller.
class Admin::LoginController; def rescue_action(e) raise e end; end

class Admin::LoginControllerTest < ActionController::TestCase
  def setup
    @controller = Admin::LoginController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  # Replace this with your real tests.
  def test_truth
    assert true
  end


  def test_login_index
    get :login_index
    assert_response 200
  end

  def test_authenticate
    post :authenticate, :nz => {:n => 'testuser', :p => 'testpass'}
    assert_redirected_to :controller => 'admin/article', :action => 'new_article'
  end
  def test_authenticate__fail
    post :authenticate, :nz => {:n => 'testuser', :p => 'wrongpass'}
    assert_response(403)
  end

  def test_logout
    @request.session['person'] = 'ok'
    post :logout
    assert_redirected_to :controller => 'admin/login', :action => 'login_index'
  end

end
