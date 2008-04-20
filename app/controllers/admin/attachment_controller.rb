class Admin::AttachmentController < AdminController

  def manage_don_attachment
    @don_attachments = DonAttachment.paginate(:page => params[:page],:per_page => 30,:order => 'id DESC')
  end

  def manage_don_attachment_detail
    if params["id"]
      @don_attachment = DonAttachment.find(params["id"])
    else
      redirect_to :back
    end
  end

  def edit_don_attachment
    p2 = params["don_attachment"]
    if p2 and p2['id']
      params = p2.dup
      if tmp = params.delete('aid')
        params['join_article_ids'] = tmp
      end
      if tmp = params.delete('bp')
        params['curr_article_ids'] = tmp
      end
      @don_attachment = DonAttachment.find(params['id'])
      @don_attachment.update_attachment_attributes(params, nil)
      @don_attachment.save
    end
    redirect_to :back
  end

  def don_attachment_save
    begin
      @don_attachment = DonAttachment.new(params["don_attachment"])
      if @don_attachment.save
        redirect_to :action => "manage_don_attachment"
      else
        render :action => 'picture_get', :controller => 'notes'
      end
    rescue
      raise
      render :text => 'fail', :status => 403
    end
  end

end
