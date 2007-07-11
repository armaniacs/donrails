require File.dirname(__FILE__) + '/../test_helper'

class DonAttachmentTest < Test::Unit::TestCase
  fixtures :don_attachments, :articles, :dona_daas

  def setup
    @da1 = DonAttachment.find(1)
    @da =  DonAttachment.new
  end

  def test_truth
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
