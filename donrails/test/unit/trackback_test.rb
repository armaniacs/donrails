require File.dirname(__FILE__) + '/../test_helper'

class TrackbackTest < Test::Unit::TestCase
  fixtures :trackbacks, :articles, :categories

  def setup
    @trackback = Trackback.new
  end

  # Replace this with your real tests.
  def test_truth
    assert_kind_of Trackback,  @trackback
  end
end
