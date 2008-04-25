# tested by MS windows live writer.
#
module MetaWeblogStructs
  class Article < ActionWebService::Struct
    member :description,        :string
    member :title,              :string
    member :postid,             :string
    member :url,                :string
    member :link,               :string
    member :permaLink,          :string
    member :categories,         [:string]
    member :mt_text_more,       :string
    member :mt_excerpt,         :string
    member :mt_keywords,        :string
    member :mt_allow_comments,  :int
    member :mt_allow_pings,     :int
    member :mt_convert_breaks,  :string
    member :mt_tb_ping_urls,    [:string]
    member :dateCreated,        :time
  end

  class MediaObject < ActionWebService::Struct
    member :bits, :string
    member :name, :string
    member :type, :string
  end

  class Url < ActionWebService::Struct
    member :url, :string
  end

  class Category < ActionWebService::Struct
    member :description, :string
  end
end


class MetaWeblogApi < ActionWebService::API::Base
  inflect_names false

  api_method :getCategories,
    :expects => [ {:blogid => :string}, {:username => :string}, {:password => :string} ],
    :returns => [[MetaWeblogStructs::Category]]

  api_method :getPost,
    :expects => [ {:postid => :string}, {:username => :string}, {:password => :string} ],
    :returns => [MetaWeblogStructs::Article]

  api_method :getRecentPosts,
    :expects => [ {:blogid => :string}, {:username => :string}, {:password => :string}, {:numberOfPosts => :int} ],
    :returns => [[MetaWeblogStructs::Article]]

  api_method :deletePost,
    :expects => [ {:appkey => :string}, {:postid => :string}, {:username => :string}, {:password => :string}, {:publish => :int} ],
    :returns => [:bool]

  api_method :editPost,
    :expects => [ {:postid => :string}, {:username => :string}, {:password => :string}, {:struct => MetaWeblogStructs::Article}, {:publish => :int} ],
    :returns => [:bool]

  api_method :newPost,
    :expects => [ {:blogid => :string}, {:username => :string}, {:password => :string}, {:struct => MetaWeblogStructs::Article}, {:publish => :int} ],
    :returns => [:string]

   api_method :newMediaObject,
     :expects => [ {:blogid => :string}, {:username => :string}, {:password => :string}, {:data => MetaWeblogStructs::MediaObject} ],
     :returns => [MetaWeblogStructs::Url]

end


class MetaWeblogService < DonWebService
  web_service_api MetaWeblogApi
  before_invocation :authenticate

  def getCategories(blogid, username, password)
    Category.find(:all).collect do |c| 
      MetaWeblogStructs::Article.new(
                                     :description => c.name
                                     )
    end
  end

  def getPost(postid, username, password)
    article = Article.find(postid)

    article_dto_from(article)
  end

  def getRecentPosts(blogid, username, password, numberOfPosts)
    Article.find(:all, :order => "article_mtime DESC", :limit => numberOfPosts).collect{ |c| article_dto_from(c) }
  end

  def newPost(blogid, username, password, struct, publish)
    article = Article.new
    article.body        = struct['description'] || ''
    article.title       = struct['title'] || ''
    article.article_date = struct['dateCreated'].to_time.utc rescue Time.now.utc
    article.format = 'html'
    article.create_enrollment
    article.enrollment.title = article.title
    author1 = Author.find_by_name(username)
    article.author_id = author1.id
    if publish == false
      article.hidden   = 1
    else
      article.hidden   = 0
    end

    if struct['categories']
      article.categories.clear
      Category.find(:all).each do |c|
        if struct['categories'].include?(c.name)
          DonaCa.create(:article => article, :category => c)
        end
      end
    end

    if article.save
      article.id.to_s
    else
      raise article.errors.full_messages * ", "
    end
  end

  def deletePost(appkey, postid, username, password, publish)
    article = Article.find(postid)
    article.destroy
    true
  end

  def editPost(postid, username, password, struct, publish)
    article = Article.find(postid)
    article.body        = struct['description'] || ''
    article.title       = struct['title'] || ''
    article.format = 'html'
    if publish == false
      article.hidden   = 1
    else
      article.hidden   = 0
    end
    author1 = Author.find_by_name(username)
    article.author_id = author1.id
    article.article_date  = struct['dateCreated'].to_time.getlocal unless struct['dateCreated'].blank?

    if struct['categories']
      article.categories.clear
      Category.find(:all).each do |c|
        if struct['categories'].include?(c.name)
          DonaCa.create(:article => article, :category => c)
        end
      end
    end
    article.save
    true
  end

   def newMediaObject(blogid, username, password, data)
     picture = Picture.new(:content_type => data['type'])
     picture.title = File.basename(data['name']).gsub(/[^\w._-]/, '_')
     picture.filesave(data['bits'])
     picture.save

     MetaWeblogStructs::Url.new("url" => controller.url_for(:controller => "notes", :action => "show_image", :id => picture.id))
   end

  def article_dto_from(article)
    article = don_get_object(article, 'html')
    MetaWeblogStructs::Article.new(
      :description       => article.body_to_html,
      :title             => article.title,
      :postid            => article.id.to_s,
      :url               => article_url(article).to_s,
      :link              => article_url(article).to_s,
      :permaLink         => article_url(article).to_s,
      :categories        => article.categories.collect { |c| c.name },
#      :mt_text_more      => article.extended.to_s,
#      :mt_excerpt        => article.excerpt.to_s,
#      :mt_keywords       => article.keywords.to_s,
#      :mt_allow_comments => article.allow_comments? ? 1 : 0,
#      :mt_allow_pings    => article.allow_pings? ? 1 : 0,
#      :mt_convert_breaks => (article.text_filter.name.to_s rescue ''),
#      :mt_tb_ping_urls   => article.pings.collect { |p| p.url },
      :dateCreated       => (article.article_mtime.to_formatted_s(:db) rescue "")
      )
  end

  protected

  def article_url(article)
    controller.url_for :controller=>"notes", :action =>"show_enrollment", :id => article.enrollment_id
  end

  def server_url
    controller.url_for(:only_path => false, :controller => "notes")
  end

  def pub_date(time)
    time.strftime "%a, %e %b %Y %H:%M:%S %Z"
  end
end
