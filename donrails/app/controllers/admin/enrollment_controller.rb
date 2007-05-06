class Admin::EnrollmentController < AdminController
  cache_sweeper :article_sweeper, :only => [ :delete_enrollment ]

  def manage_enrollment
    if params[:nohidden] == '1'
      @enrollments_pages, @enrollments = paginate(:enrollment, :per_page => 30,
                                                  :order_by => 'id DESC',
                                                  :conditions => ["hidden IS NULL OR hidden = 0"]
                                                  )
    else
      @enrollments_pages, @enrollments = paginate(:enrollment, :per_page => 30,
                                                  :order_by => 'id DESC'
                                                  )
    end
  end


  def delete_enrollment
    flash[:note] = ''
    flash[:note2] = ''
    now_delete = Array.new
    c = params["deleteid"].nil? ? [] : params["deleteid"]
    c.each do |k, v|
      if v.to_i == 1
        if Enrollment.exists?(k.to_i)
          b = Enrollment.find(k.to_i)
          b.articles.each do |ba|
            ba.enrollment_id = nil
            ba.save
          end
          flash[:note2] += '<br>Delete:' + k
          now_delete.push(k)
          b.destroy
        else
          flash[:note2] += '<br>Not exists:' + k
        end
      end
    end
    if c = params["hideid"]
      c.each do |k, v|
        if Enrollment.exists?(k.to_i)
          pf = Enrollment.find(k.to_i)
          stmp = pf.hidden
          if v.to_i == 1 and stmp != 1
            pf.update_attribute('hidden', 1)
          elsif v.to_i == 0 and stmp != 0
            pf.update_attribute('hidden', 0)
          end
          unless stmp == pf.hidden
            flash[:note2] += '<br>Hyde status:' + k + ' is ' + pf.hidden.to_s
          end
        else
          unless now_delete.include?(k)
            flash[:note2] += '<br>Not exists:' + k
          end
        end
      end
    end
    redirect_to :action => "manage_enrollment"
  end

end
