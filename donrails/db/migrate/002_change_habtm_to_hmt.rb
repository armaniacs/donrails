class ChangeHabtmToHmt < ActiveRecord::Migration

  class Article < ActiveRecord::Base
    #     has_and_belongs_to_many :categories, 
    #     :join_table => "categories_articles"
    has_and_belongs_to_many :old_categories, 
    :join_table => "categories_articles", :class_name => "Category"
    has_many :dona_cas
    has_many :new_categories, :through => :dona_cas, :source => :category

    #     has_and_belongs_to_many :don_attachments, 
    #     :join_table => "don_attachments_articles"
    has_and_belongs_to_many :old_don_attachments, 
    :join_table => "don_attachments_articles", :class_name => "DonAttachment"
    has_many :dona_daas
    has_many :new_don_attachments, :through => :dona_daas, :source => :don_attachment

  end

  class Category < ActiveRecord::Base
    has_and_belongs_to_many :old_articles, 
    :join_table => "categories_articles",
    :class_name => "Article"  

    has_many :dona_cas
    has_many :new_articles, :through => :dona_cas, :source => :article
  end

  class DonAttachment < ActiveRecord::Base
    has_and_belongs_to_many :old_articles, 
    :join_table => "don_attachments_articles",
    :class_name => "Article"  

    has_many :dona_daas
    has_many :new_articles, :through => :dona_daas, :source => :article
  end


  class DonaCa < ActiveRecord::Base
    belongs_to :article
    belongs_to :category
  end

  class DonaDaa < ActiveRecord::Base
    belongs_to :article
    belongs_to :don_attachment
  end


  def self.up
    # Create dona_ca table
    create_table :dona_cas do |t|
      t.column :article_id, :integer
      t.column :category_id, :integer
      t.column :task, :integer
    end
    # Create dona_daa table
    create_table :dona_daas do |t|
      t.column :article_id, :integer
      t.column :don_attachment_id, :integer
      t.column :task, :integer
    end


    Article.find(:all).each do |article|
      # Copy data from "categories_articles" table to dona_ca
      article.old_categories each do |category|
        dona_ca = DonaCa.new
        dona_ca.article = article
        dona_ca.category = category
        dona_ca.save
      end

      # Copy data from "don_attachments_articles" table to dona_daa
      article.old_don_attachments each do |don_attachment|
        dona_daa = DonaDaa.new
        dona_daa.article = article
        dona_daa.don_attachment = don_attachment
        dona_daa.save
      end
    end

    # Delete categories_articles table
    drop_table :categories_articles
    # Delete don_attachments_articles table
    drop_table :don_attachments_articles
  end


  def self.down
    # Create categories_articles table
    create_table :categories_articles, :id => false do |t|
      t.column :category_id, :integer
      t.column :article_id, :integer
    end
    # Create don_attachments_articles table
    create_table :don_attachments_articles, :id => false do |t|
      t.column :don_attachment_id, :integer
      t.column :article_id, :integer
    end
    
    # Copy data from dona_ca table to categories_articles table
    Article.find(:all).each do |article|
      article.old_categories << article.new_categories
    end
    # Copy data from dona_daa table to don_attachments_articles table
    Article.find(:all).each do |article|
      article.old_don_attachments << article.new_don_attachments
    end
    
    # Delete dona_ca table
    drop_table :dona_cas
    # Delete dona_daa table
    drop_table :dona_daas
  end
end
