require 'pony'

class ApplicationController < ActionController::Base
  protect_from_forgery
  before_filter :detect_region, :set_current_user

  rescue_from ActionView::MissingTemplate do |exception|
  end

  protected
    def detect_region
      @region = Region.find_by_name(params[:region].downcase) if (params[:region] && (params[:region].is_a? String))
    end

    def set_current_user
       Authorization.current_user = current_user
    end

  def send_new_machine_notification(machine, location)
    Pony.mail(
      :to => Region.find_by_name('portland').users.collect {|u| u.email},
      :from => 'admin@pinballmap.com',
      :subject => "PBM - Someone entered a new machine name",
      :body => [machine.name, location.name, location.region.name, "(entered via #{request.user_agent})"].join("\n")
    )
  end
end
