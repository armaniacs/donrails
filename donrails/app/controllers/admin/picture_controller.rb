class Admin::PictureController < AdminController
  cache_sweeper :article_sweeper, :only => [ :delete_picture, :picture_save ]

  def manage_picture
    @pictures_pages, @pictures = paginate(:picture,:conditions => ['format = \'picture\''], :per_page => 30,:order => 'id DESC')
  end
  def manage_picture_detail
    if params["id"]
      @picture = Picture.find(params["id"])
    else
      redirect_to :back
    end
  end

  def edit_picture
    p2 = params["picture"]
    if p2 and p2['id']
      @picture = Picture.find(p2['id'])
      if p2['aid']
        p2['aid'].split(/\s+/).each do |pe|
          na = Article.find(pe)
          @picture.articles.push_with_attributes(na)
        end
      end
      @picture.body = p2['body'] if p2['body']
      if params['bp']
        params['bp'].each do |k,v|
          if v.to_i == 0
            uba = Article.find(k)
            @picture.articles.delete(uba)
          end
        end
      end
      @picture.save
    end
    redirect_to :back
  end

  def delete_picture
    flash[:note] = ''
    flash[:note2] = ''
    begin
      if cf = params["filedeleteid"]
        cf.each do |k, v|
          if v.to_i == 1
            pf = Picture.find(k.to_i)
            begin
              File.delete pf.path
            rescue
              flash[:note] += '<br>' + $!
            end
            flash[:note2] += '<br>Delete File:' + k
            Picture.delete(k.to_i)
          end
        end
      end
      if c = params["deleteid"]
        c.each do |k, v|
          if v.to_i == 1
            Picture.delete(k.to_i)
            flash[:note2] += '<br>Delete:' + k
          end
        end
      end
      if c = params["hideid"]
        c.each do |k, v|
          pf = Picture.find(k.to_i)
          stmp = pf.hidden
          if v.to_i == 1
            pf.update_attribute('hidden', 1)
          elsif v.to_i == 0
            pf.update_attribute('hidden', 0)
          end

          unless stmp == pf.hidden
            flash[:note2] += '<br>Hyde status:' + k + ' is ' + pf.hidden.to_s
          end
        end
      end
    rescue
      flash[:note] += '<br>' + $!
    end
    redirect_to :action => "manage_picture"
  end


  def picture_save
    begin
      @picture = Picture.new(params['picture'])
      if @picture.save
        redirect_to :action => "manage_picture"
      else
        render :action => 'picture_get', :controller => 'notes'
      end
    rescue
      render :text => 'fail', :status => 403
    end
  end

end
