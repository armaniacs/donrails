require File.dirname(__FILE__) + '/../test_helper'

class EnrollmentTest < Test::Unit::TestCase
  fixtures :enrollments, :articles

  def setup
    @a1 = Article.find(1)
    @e1 = Enrollment.find(1)
    @enrollment = Enrollment.new
  end

  def test_truth
    assert_kind_of Enrollment, @enrollment
    @enrollment.save
    assert_kind_of Time, @enrollment.created_at
    assert_kind_of Article, @e1.articles.first
  end

  def test_search
    result = Enrollment.search('first body')
    assert_equal(@a1, result.first.articles.first)
  end

end
