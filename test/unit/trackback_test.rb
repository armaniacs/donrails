require File.dirname(__FILE__) + '/../test_helper'

class TrackbackTest < ActiveSupport::TestCase
  fixtures :trackbacks, :articles, :categories, :don_envs

  def setup
    @trackback = Trackback.new
    @a1 = Article.find(1)
    @t4 = Trackback.new("blog_name" => "test blog_name name name t4",
                        "title" => "test title t4",
                        "excerpt" => "I hope to go my, sg, tw",
                        "url" => "http://example.com/valid_path.html",
                        "category_id" => 1,
                        "ip" => "127.0.0.1")
  end

  # Replace this with your real tests.
  def test_truth
    assert_kind_of Trackback,  @trackback
    assert_kind_of Article,  @a1
    assert_kind_of Trackback,  @t4
  end

  def test_1
    @t4.article = @a1
    @t4.save
  end
end
