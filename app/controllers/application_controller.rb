require 'pony'

class ApplicationController < ActionController::Base
  protect_from_forgery
  before_filter :detect_region, :set_current_user

  rescue_from ActionView::MissingTemplate do |exception|
  end

  def send_new_machine_notification(machine, location)
    Pony.mail(
      :to => Region.find_by_name('portland').users.collect {|u| u.email},
      :from => 'admin@pinballmap.com',
      :subject => "PBM - New machine name",
      :body => [machine.name, location.name, location.region.name, "(entered from #{request.remote_ip} via #{request.user_agent})"].join("\n")
    )
  end

  def send_new_location_notification(params, region)
    Pony.mail(
      :to => region.users.collect {|u| u.email},
      :bcc => User.all.select {|u| u.is_super_admin }.collect {|u| u.email},
      :from => 'admin@pinballmap.com',
      :subject => "PBM - New location suggested for the #{region.name} pinball map",
      :body => <<END
(A new pinball spot has been submitted for your region! Please verify the address on http://maps.google.com and then paste that Google Maps address into http://pinballmap.com/admin. Thanks!)\n
Location Name: #{params['location_name']}\n
Street: #{params['location_street']}\n
City: #{params['location_city']}\n
State: #{params['location_state']}\n
Zip: #{params['location_zip']}\n
Phone: #{params['location_phone']}\n
Website: #{params['location_website']}\n
Operator: #{params['location_operator']}\n
Machines: #{params['location_machines']}\n
Their Name: #{params['submitter_name']}\n
Their Email: #{params['submitter_email']}\n
END
    )
  end

  def return_response(data,root,includes=[],methods=[])
    render :json => {root=>data.as_json(include: includes,methods: methods,root:false)}
  end

  private
    def mobile_device?
      if session[:mobile_param]
        session[:mobile_param] == "1"
      else
        (request.user_agent =~ /Mobile|webOS/) && (request.user_agent !~ /iPad/)
      end
    end

    helper_method :mobile_device?

  protected
    def detect_region
      @region = Region.find_by_name(params[:region].downcase) if (params[:region] && (params[:region].is_a? String))
    end

    def set_current_user
       Authorization.current_user = current_user
    end

end
