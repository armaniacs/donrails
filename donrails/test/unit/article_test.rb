require File.dirname(__FILE__) + '/../test_helper'

class ArticleTest < Test::Unit::TestCase
  fixtures :articles, :categories, :comments, :comments_articles, :categories_articles

  def setup
    @a1 = Article.find(1)
    @article = Article.new
  end

  # Replace this with your real tests.
  def test_truth
    assert_kind_of Article,  @article
  end

  def test_renew_mtime
    assert_nil @article.article_mtime
    @article.renew_mtime
    assert_not_nil(@article.article_mtime)

    assert_equal('Fri Jan 01 00:00:01 JST 1999', @a1.article_mtime.to_s)
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
