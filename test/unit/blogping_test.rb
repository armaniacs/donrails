require File.dirname(__FILE__) + '/../test_helper'

class BlogpingTest < ActiveSupport::TestCase
  fixtures :blogpings

  def setup
#    @blogping = Blogping.find(1)
    @blogping = Blogping.new
  end

  # Replace this with your real tests.
  def test_truth
    assert_kind_of Blogping,  @blogping
  end
end
