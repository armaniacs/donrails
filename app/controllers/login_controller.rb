require 'kconv'
class LoginController < ApplicationController

  include Akismet

  class << self
    include ApplicationHelper
  end
  @@dgc = don_get_config

  before_filter :authorize, :except => [:login_index, :authenticate]
  after_filter :compress
  after_filter :clean_memory

  auto_complete_for :author, :name
  auto_complete_for :category, :name

  layout "login", :except => [:login_index, :index]

  def login_index
    redirect_to :controller => 'admin/login', :action => 'login_index'
  end
end
