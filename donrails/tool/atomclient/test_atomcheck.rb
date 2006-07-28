require 'test/unit'
require 'atomcheck'

#class TC_Atomcheck < Test::Unit::TestCase
class TC_AtomStatus < Test::Unit::TestCase
  def setup
    @obj = AtomStatus.new
    @obj2 = AtomStatus.new
    @obj3 = AtomStatus.new

    @target_url = "http://example.com/atom/post"
    @title = "test for test_atomcheck.rb"
    @body = Time.now.ctime.to_s
  end

  def test_check
    aris0 = Article.new("target_url" => @target_url, "title" => @title, 
                        "body" => @body, "status" => 201)
    aris0.save
    @id = aris0.id

    # check(target_url, title, body)
    assert_equal(0, @obj.check(@target_url, @title, @body))

    body = @body + 'test_check'
    @id2 = @obj2.check(@target_url, @title, body)

    assert_not_equal(0, @id2)

    Article.delete(@id)
    Article.delete(@id2)
  end

  def test_update
    aris3 = Article.new("target_url" => @target_url, "title" => @title, 
                        "body" => @body + 'test_update')
    aris3.save
    @id3 = aris3.id
    
    assert(@obj3.update(@id3, 404))
    Article.delete(@id3)
  end

end
