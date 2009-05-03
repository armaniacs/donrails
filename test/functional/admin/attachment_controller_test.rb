require File.dirname(__FILE__) + '/../../test_helper'
require 'admin/attachment_controller'

# Re-raise errors caught by the controller.
class Admin::AttachmentController; def rescue_action(e) raise e end; end

class Admin::AttachmentControllerTest < ActionController::TestCase
  def setup
    @controller = Admin::AttachmentController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  # Replace this with your real tests.
  def test_truth
    assert true
  end
end
