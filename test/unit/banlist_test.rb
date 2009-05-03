require File.dirname(__FILE__) + '/../test_helper'

class BanlistTest < ActiveSupport::TestCase
  fixtures :banlists

  # Replace this with your real tests.
  def test_truth
    assert true
  end

  def test_1
    @b1 = Banlist.find(1)
    assert_kind_of Banlist, @b1
    assert_equal(1, @b1.id)
    assert_equal("regexp", @b1.banformat)
  end
end
