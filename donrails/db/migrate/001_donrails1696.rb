#
# This file is first version of ActiveRecord::Migration for donrails.
# 
# For new user:
#   You have to run 'rake db:migrate' to apply this file.
#
# For user before 1.6.9.6(snapshot20070708):
#   You have not to run 'rake db:migrate' to apply this file.
#

class Donrails1696 < ActiveRecord::Migration
  def self.up

    create_table "articles", :force => true do |t|
      t.column "title",         :text
      t.column "body",          :text
      t.column "size",          :integer
      t.column "article_date",  :timestamp,                :null => false
      t.column "article_mtime", :timestamp,                :null => false
      t.column "hnfid",         :integer
      t.column "author_id",     :integer
      t.column "format",        :string,    :limit => 100
      t.column "hidden",        :integer
      t.column "enrollment_id", :integer
    end

    add_index "articles", ["id"], :name => "id", :unique => true

    create_table "authors", :force => true do |t|
      t.column "name",     :string,  :limit => 100, :default => "", :null => false
      t.column "nickname", :string,  :limit => 100
      t.column "pass",     :string,  :limit => 100
      t.column "summary",  :text
      t.column "writable", :integer,                                :null => false
    end

    add_index "authors", ["id"], :name => "id", :unique => true
    add_index "authors", ["name"], :name => "name", :unique => true

    create_table "banlists", :force => true do |t|
      t.column "format",  :string,  :limit => 100
      t.column "pattern", :text
      t.column "white",   :integer
    end

    add_index "banlists", ["id"], :name => "id", :unique => true

    create_table "blogpings", :force => true do |t|
      t.column "server_url", :string,  :default => "", :null => false
      t.column "active",     :integer
    end

    add_index "blogpings", ["id"], :name => "id", :unique => true
    add_index "blogpings", ["server_url"], :name => "server_url", :unique => true

    create_table "categories", :force => true do |t|
      t.column "name",        :string,  :limit => 100, :default => "", :null => false
      t.column "parent_id",   :integer
      t.column "description", :text
    end

    add_index "categories", ["id"], :name => "id", :unique => true
    add_index "categories", ["name"], :name => "name", :unique => true
    add_index "categories", ["parent_id"], :name => "fk_category"

    create_table "categories_articles", :id => false, :force => true do |t|
      t.column "category_id", :integer, :null => false
      t.column "article_id",  :integer, :null => false
    end

    add_index "categories_articles", ["article_id"], :name => "fk_cp_article"

    create_table "comments", :force => true do |t|
      t.column "password",   :string,    :limit => 100
      t.column "date",       :timestamp,                :null => false
      t.column "title",      :text
      t.column "author",     :string,    :limit => 100
      t.column "url",        :text
      t.column "ipaddr",     :string,    :limit => 100
      t.column "body",       :text
      t.column "hidden",     :integer
      t.column "spam",       :integer
      t.column "article_id", :integer
    end

    add_index "comments", ["id"], :name => "id", :unique => true

    create_table "don_attachments", :force => true do |t|
      t.column "title",        :text
      t.column "path",         :text
      t.column "size",         :integer
      t.column "content_type", :string,  :limit => 100
      t.column "body",         :text
      t.column "hidden",       :integer
      t.column "format",       :string,  :limit => 100
    end

    add_index "don_attachments", ["id"], :name => "id", :unique => true

    create_table "don_attachments_articles", :id => false, :force => true do |t|
      t.column "don_attachment_id", :integer, :null => false
      t.column "article_id",        :integer, :null => false
    end

    add_index "don_attachments_articles", ["article_id"], :name => "fk_cp_article"

    create_table "don_envs", :force => true do |t|
      t.column "hidden",                :integer
      t.column "image_dump_path",       :text
      t.column "admin_user",            :string,  :limit => 100
      t.column "admin_password",        :string,  :limit => 100
      t.column "admin_mailadd",         :text
      t.column "rdf_title",             :text
      t.column "rdf_description",       :text
      t.column "rdf_copyright",         :text
      t.column "rdf_managingeditor",    :text
      t.column "rdf_webmaster",         :text
      t.column "baseurl",               :text
      t.column "url_limit",             :integer,                :default => 5
      t.column "default_theme",         :string,  :limit => 100
      t.column "trackback_enable_time", :integer
      t.column "akismet_key",           :text
      t.column "notify_level",          :integer,                :default => 1
      t.column "ping_async",            :integer,                :default => 0
    end

    add_index "don_envs", ["id"], :name => "id", :unique => true

    create_table "don_pings", :force => true do |t|
      t.column "article_id",    :integer
      t.column "url",           :text
      t.column "created_at",    :datetime
      t.column "send_at",       :datetime
      t.column "status",        :string,   :limit => 100
      t.column "response_body", :text
      t.column "counter",       :integer,                 :default => 0
    end

    add_index "don_pings", ["id"], :name => "id", :unique => true

    create_table "don_rbls", :force => true do |t|
      t.column "rbl_type", :string, :limit => 100
      t.column "hostname", :text
    end

    add_index "don_rbls", ["id"], :name => "id", :unique => true

    create_table "enrollments", :force => true do |t|
      t.column "title",      :text
      t.column "hidden",     :integer
      t.column "created_at", :datetime
      t.column "updated_at", :datetime
    end

    add_index "enrollments", ["id"], :name => "id", :unique => true

    create_table "plugins", :force => true do |t|
      t.column "name",        :string,  :limit => 100, :default => "", :null => false
      t.column "description", :text,                   :default => "", :null => false
      t.column "manifest",    :string,  :limit => 100, :default => "", :null => false
      t.column "activation",  :boolean
    end

    add_index "plugins", ["id"], :name => "id", :unique => true
    add_index "plugins", ["name"], :name => "name", :unique => true

    create_table "trackbacks", :force => true do |t|
      t.column "article_id",  :integer
      t.column "category_id", :integer
      t.column "blog_name",   :text
      t.column "title",       :text
      t.column "excerpt",     :text
      t.column "url",         :text
      t.column "ip",          :string,   :limit => 100
      t.column "created_at",  :datetime
      t.column "hidden",      :integer
      t.column "spam",        :integer
    end

    add_index "trackbacks", ["id"], :name => "id", :unique => true

  end

  def self.down
  end
end
