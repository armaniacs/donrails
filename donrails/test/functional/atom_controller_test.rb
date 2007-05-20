require File.dirname(__FILE__) + '/../test_helper'
require 'atom_controller'

# Re-raise errors caught by the controller.
class AtomController; def rescue_action(e) raise e end; end

class AtomControllerTest < Test::Unit::TestCase
  def setup
    @controller = AtomController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  # Replace this with your real tests.
  def test_index
    get :index
    assert_response 401

    @request.env['REMOTE_ADDR'] = '127.0.0.1'
    get :index
    assert_response :success
  end

  def test_post
    @request.env['REMOTE_ADDR'] = '127.0.0.1'
#    post :post
#    assert_response :success

    # XXX 2007/05/19
    # before check atom_update_article2 in ./helpers/application_helper.rb
#    @user = 'araki'
#    post :post
#    assert_response :success
  end

  def test_feed
    get :feed
    assert_response :success

    get :feed, :aid => 1
    assert_response :success
    get :feed, :aid => 2
    assert_response :success
    get :feed, :aid => 3
    assert_response :success
    get :feed, :aid => 50000
    assert_response 403
  end

end
