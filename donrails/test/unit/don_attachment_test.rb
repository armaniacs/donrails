require File.dirname(__FILE__) + '/../test_helper'

class DonAttachmentTest < Test::Unit::TestCase
  fixtures :don_attachments, :articles, :don_attachments_articles

  def setup
    @da1 = DonAttachment.find(1)
    @da =  DonAttachment.new
  end

  def test_truth
    assert_kind_of DonAttachment,  @da
    @da.articles.create
    assert_kind_of Article, @da.articles.first

    @da2 = DonAttachment.new
    @da2.articles.build
    assert_kind_of Article, @da2.articles.first
  end

  def test_base_part_of
  end

  def test_don_attachment
  end

  def test_attachment_assign
  end

  def test_filesave
  end

  def test_update_attachment_attributes
  end


end
