require File.dirname(__FILE__) + '/../test_helper'

class AuthorTest < Test::Unit::TestCase
  fixtures :authors, :articles

  def setup
    @author = Author.find(1)
  end

  def test_authenticate
    assert_kind_of Author, @author
    assert_equal(@author, Author.authenticate("araki", "pass"))
  end
end
