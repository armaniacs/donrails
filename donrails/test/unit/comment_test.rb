require File.dirname(__FILE__) + '/../test_helper'

class CommentTest < Test::Unit::TestCase
  fixtures :comments, :articles, :comments_articles

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
    @c3.articles.push_with_attributes(@a1)
    @c3.save
  end
end
