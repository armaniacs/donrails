require File.dirname(__FILE__) + '/../test_helper'

class ArticleTest < Test::Unit::TestCase
  fixtures :articles, :categories, :comments, :enrollments, :trackbacks, :don_envs

  def setup
    @a1 = Article.find(1)
    @article = Article.new
  end

  # Replace this with your real tests.
  def test_truth
    assert_kind_of Article,  @article
    @article.create_enrollment
    assert_kind_of Enrollment, @article.enrollment

    @a2 = Article.new
    @a2.build_enrollment
    assert_kind_of Enrollment, @a2.enrollment
  end

  def test_renew_mtime
    assert_match(/Fri Jan 01 00:00:01 .+ 1999/, @a1.article_mtime.to_s)
    @a1.renew_mtime
    assert_no_match(/Fri Jan 01 00:00:01 .+ 1999/, @a1.article_mtime.to_s)

    assert_nil @article.article_mtime
    @article.renew_mtime
    assert_not_nil(@article.article_mtime)

    aam = @article.article_mtime.dup
    tb1 = Trackback.new
    tb1.article = @article
    tb1.save
    assert_equal(aam.to_s, @article.article_mtime.to_s)

    @article.trackbacks.clear
    assert_equal(aam.to_s, @article.article_mtime.to_s)
  end

  def test_search
    result = Article.search('first body')
    assert_equal(@a1, result.first)
  end

  def test_send_trackback
    articleurl = ['http://localhost:3000/notes/id/1']
    urllist = ['http://localhost:3000/notes/catch_trackback']
    @a1.send_trackback(articleurl, urllist)
  end

  def test_send_ping2
    articleurl = ['http://localhost:3000/notes/id/1']
    urllist = ['http://localhost:3000/notes/catch_ping']
    @a1.send_pings2(articleurl, urllist)
  end

  def test_sendping
    @a1.sendping
  end

end
