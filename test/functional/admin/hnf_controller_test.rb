require File.dirname(__FILE__) + '/../../test_helper'
require 'admin/hnf_controller'

# Re-raise errors caught by the controller.
class Admin::HnfController; def rescue_action(e) raise e end; end

class Admin::HnfControllerTest < ActionController::TestCase
  def setup
    @controller = Admin::HnfController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  # Replace this with your real tests.
  def test_truth
    assert true
  end
end
