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

  def test_1
    assert_nothing_raised {
      a3 = Article.new
      a3.title = 'test_1 title'
      a3.build_enrollment
      a3.save
      
      a3id = a3.id
      a3eid = a3.enrollment_id

      e3 = Enrollment.find(a3eid)
      a3.destroy
      
      e3a = Enrollment.find(a3eid)
    }
  end

  def test_2
    assert_nothing_raised {
      a3 = Article.new
      a3.title = 'test_1 title'
      a3.build_enrollment
      a3.save
      
      a3id = a3.id
      a3eid = a3.enrollment_id
      
      e3 = Enrollment.find(a3eid)
      e3.articles.clear
      
      e3a = Enrollment.find(a3eid)
    }
  end

end
