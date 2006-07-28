### $ ruby -I../../lib application_helper_test.rb

require 'test/unit'
#require '../../lib/delegator'
require 'application_helper'

class TC_ApplicationHelper < Test::Unit::TestCase
  include ApplicationHelper

  def setup
  end

  def teardown
  end

  def test_parsecontent
    data1 = '<content>data1</content>'
    data2 = '<content type="text/html">data2</content>'
    data3 = '<content type="text/html"><h1>data3</h1></content>'
    data4 = '<content color="red" type="text/html"><h1>data4</h1></content>'
    data5 = '<content color="red" type="text/html"><h1><content>data5</content></h1></content>'

    assert_equal('data1', parsecontent(data1))
    assert_equal('data2', parsecontent(data2))
    assert_equal('<h1>data3</h1>', parsecontent(data3))
    assert_equal('<h1>data4</h1>', parsecontent(data4))
    assert_equal('<h1><content>data5</content></h1>', parsecontent(data5))

  end

end
