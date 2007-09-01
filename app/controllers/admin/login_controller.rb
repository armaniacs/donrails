class Admin::LoginController < AdminController
  def login_index
    flash.keep(:op)
    flash.keep(:pbp)
    render :action => "index"
  end

  def authenticate
    flash.keep(:op)
    flash.keep(:pbp)

    name = String.new
    password = String.new
    case request.method
    when :post
      c = params["nz"]
      if c
        namae = c["n"]
        password = c["p"]
      end

      if namae == @@dgc.admin_user and password == @@dgc.admin_password
        session["person"] = "ok"

        if flash[:op] =~ /^\/admin\/?$/
          redirect_to :controller => 'admin/article', :action => "new_article"
          return
        elsif flash[:pbp] && flash[:pbp]["action"] == "manage_don_env"
          redirect_to :controller => 'admin/system', :action => "manage_don_env"
          return
        elsif flash[:pbp]
          redirect_to flash[:pbp] 
          return
        else
          redirect_to  :controller => 'admin/article', :action => "new_article"
          return
        end
      else
        flash[:notice] = "Wrong Password. Please input carefully."
        if flash[:op] == nil
          render :status => 403, :text => 'fail'
          return
        elsif flash[:op] == '/admin/login/authenticate'
          redirect_to '/admin/login' 
          return
        else
          redirect_to flash[:op] 
          return
        end

      end
    else
      flash[:notice] = "Wrong method."
      redirect_to :action => "login_index"
      return
    end
  end

  def logout
    request.reset_session
    session = request.session
    session["person"] = "logout"
    redirect_to :action => "login_index"
  end

end
