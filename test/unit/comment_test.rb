require File.dirname(__FILE__) + '/../test_helper'

class CommentTest < ActiveSupport::TestCase
  fixtures :comments, :articles

  # Replace this with your real tests.
  def setup
    @c1 = Comment.find(1)
    @a1 = Article.find(1)
    @c3 = Comment.new("password" => 'mogehoge',
                      "date" => Time.now,
                      "title" => 'test_1',
                      "author" => 'araki yasuhiro',
                      "url" => 'http://donrails.araki.net/t.html',
                      "ipaddr" => '127.0.0.1',
                      "body" => 'test comment body'
                      )
  end

  def test_truth
    assert_kind_of Comment, @c1
    assert_kind_of Comment, @c3
    assert_kind_of Article, @a1
  end

  def test_1
    @c3.article = @a1
    assert_equal(@c3.article.title, "first title in misc")
  end
end
