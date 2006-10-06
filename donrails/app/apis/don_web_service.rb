module DonWebServiceStructs
  class Ping < ActionWebService::Struct
    member :flerror,            :bool
    member :message,            :string
  end
end

class DonWebApi < ActionWebService::API::Base
  inflect_names false

  api_method :ping, :returns => [DonWebServiceStructs::Ping]

  api_method :extendedPing, :returns => [DonWebServiceStructs::Ping]
end

class DonWebService < ActionWebService::Base
  web_service_api DonWebApi
  attr_accessor :controller
  
  def ping(*description)
    DonWebServiceStructs::Ping.new(:flerror => false, :message => 'Ok')
  end
  alias :extendedPing :ping

  def initialize(controller)
    @controller = controller
  end
  protected

  def authenticate(name, args)
    method = self.class.web_service_api.api_methods[name]

    # Coping with backwards incompatibility change in AWS releases post 0.6.2
    begin
      h = method.expects_to_hash(args)
      raise "Invalid login" unless @user=Author.authenticate(h[:username], h[:password])
    rescue NoMethodError
      username, password = method[:expects].index(:username=>String), method[:expects].index(:password=>String)
      raise "Invalid login" unless @user = Author.authenticate(args[username], args[password])
    end
  end
end
