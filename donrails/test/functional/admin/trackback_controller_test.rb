require File.dirname(__FILE__) + '/../../test_helper'
require 'admin/trackback_controller'

# Re-raise errors caught by the controller.
class Admin::TrackbackController; def rescue_action(e) raise e end; end

class Admin::TrackbackControllerTest < Test::Unit::TestCase
  def setup
    @controller = Admin::TrackbackController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  # Replace this with your real tests.
  def test_truth
    assert true
  end


  def test_manage_trackback
    @request.session['person'] = 'ok'
    post :manage_trackback
    assert_response :success 
  end

  def test_delete_trackback
    @request.session['person'] = 'ok'
    post :delete_trackback
    assert_redirected_to :action => 'manage_trackback'

    post :delete_trackback,
    :deleteid => {'1' => '1'}
    assert_equal "<br>Delete:1", flash[:note2]
    assert_redirected_to :action => 'manage_trackback'

    post :delete_trackback, 
    :hideid => {'2' => '0'}
    assert_equal "<br>Hyde status:2 is 0", flash[:note2]
    assert_redirected_to :action => 'manage_trackback'

    post :delete_trackback, 
    :spamid => {'2' => '0'}
    assert_equal "<br>Spam status:2 is 0", flash[:note2]
    assert_redirected_to :action => 'manage_trackback'

    post :delete_trackback, 
    :hideid => {'2' => '1'}
    assert_equal "<br>Hyde status:2 is 1", flash[:note2]
    assert_redirected_to :action => 'manage_trackback'

    post :delete_trackback, 
    :spamid => {'2' => '1'}
    assert_equal "<br>Spam status:2 is 1", flash[:note2]
    assert_redirected_to :action => 'manage_trackback'

    post :delete_trackback, 
    :hideid => {'3' => '0'}
    assert_equal "<br>Hyde status:3 is 0", flash[:note2]
    assert_redirected_to :action => 'manage_trackback'

    post :delete_trackback, 
    :hideid => {'3' => '1'}
    assert_equal "<br>Hyde status:3 is 1", flash[:note2]
    assert_redirected_to :action => 'manage_trackback'

    post :delete_trackback, 
    :spamid => {'3' => '0'}
    assert_equal "<br>Spam status:3 is 0", flash[:note2]
    assert_redirected_to :action => 'manage_trackback'

    post :delete_trackback, 
    :spamid => {'3' => '1'}
    assert_equal "<br>Spam status:3 is 1", flash[:note2]
    assert_redirected_to :action => 'manage_trackback'
  end

end
