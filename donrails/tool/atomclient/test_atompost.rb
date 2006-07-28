require 'test/unit'
require 'atomcheck'

class TC_AtomPost < Test::Unit::TestCase
  def setup
    @obj = AtomPost.new
    fc = open("#{ENV['HOME']}/.donrails/atompost-test.yaml", "r")
    conf = YAML::load(fc)
    @user = conf['user']
    @uri = conf['target_url']
    @pass = conf['pass']

    @tt = 'char'
    @tb = '0123456 ' * 8
    article = Article.find(:first, :conditions => ['title = ? AND body = ? AND target_url = ?', @tt, @tb, @uri])
    article.destroy if article
  end

  def teardown
    article = Article.find(:first, :conditions => ['title = ? AND body = ? AND target_url = ?', @tt, @tb, @uri])
    article.destroy if article
  end

  def test_atompost
    res = @obj.atompost(@uri, @user, @pass,
                        @tt, @tb, Time.now, 'misc', 'html', false)
    assert_instance_of(Net::HTTPCreated, res)
  end

  def test_atompost__plain
    for i in 1..3
      @tb = @tb * 8
      @tt = @tb.size.to_s
      puts @tb.size
      res = @obj.atompost(@uri, @user, @pass,
                          @tt, @tb, Time.now, 'misc', 'plain', false)
      assert_instance_of(Net::HTTPCreated, res)
    end
  end

end
