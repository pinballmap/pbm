require 'pony'

class ApplicationController < ActionController::Base
  AUTH_REQUIRED_MSG = 'Authentication is required for this action. Please upgrade your app or pass an authentication token for this type of action.'.freeze

  acts_as_token_authentication_handler_for User, fallback: :none

  protect_from_forgery
  before_action :configure_permitted_parameters, if: :devise_controller?
  before_filter :detect_region, :set_current_user
  after_filter :flash_to_headers, :store_location

  rescue_from ActionView::MissingTemplate do
  end

  rescue_from CanCan::AccessDenied do |exception|
    redirect_to '/users/login', alert: exception.message
  end

  def flash_to_headers
    return unless request.xhr?

    response.headers['X-Message'] = flash_message
    response.headers['X-Message-Type'] = flash_type.to_s

    flash.discard
  end

  def add_host_info_to_subject(subject)
    server_name = request.host =~ /pinballmapstaging/ ? '(STAGING) ' : ''

    server_name + subject
  end

  def send_new_machine_notification(machine, location, user)
    user_info = user ? " by #{user.username} (#{user.email})" : ''

    Pony.mail(
      to: Region.find_by_name('portland').users.map(&:email),
      from: 'admin@pinballmap.com',
      subject: add_host_info_to_subject('PBM - New machine name'),
      body: [machine.name, location.name, location.region.name, "(entered from #{request.remote_ip} via #{request.user_agent}#{user_info})"].join("\n")
    )
  end

  def send_new_location_notification(params, region, user = nil)
    user_info = user ? " by #{user.username} (#{user.email})" : ''

    body = <<END
(A new pinball spot has been submitted for your region! Please verify the address on https://maps.google.com and then paste that Google Maps address into #{request.protocol}#{request.host_with_port}#{rails_admin_path}. Thanks!)\n
Location Name: #{params['location_name']}\n
Street: #{params['location_street']}\n
City: #{params['location_city']}\n
State: #{params['location_state']}\n
Zip: #{params['location_zip']}\n
Phone: #{params['location_phone']}\n
Website: #{params['location_website']}\n
Type: #{params['location_type']}\n
Operator: #{params['location_operator']}\n
Comments: #{params['location_comments']}\n
Machines: #{params['location_machines']}\n
(entered from #{request.remote_ip} via #{request.user_agent}#{user_info})\n
END
    Pony.mail(
      to: region.users.map(&:email),
      bcc: User.all.select(&:is_super_admin).map(&:email),
      from: 'admin@pinballmap.com',
      subject: add_host_info_to_subject("PBM - New location suggested for the #{region.name} pinball map"),
      body: body
    )

    UserSubmission.create(region_id: region.id, submission_type: UserSubmission::SUGGEST_LOCATION_TYPE, submission: body, user_id: user ? user.id : nil)

    location_type = LocationType.find_by_name(params['location_type'])
    operator = Operator.find_by_name(params['location_operator'])

    user_inputted_address = [params['location_street'], params['location_city'], params['location_state'], params['location_zip']].join(', ')

    (geocoded_results, lat, lon, street, city, state, zip) = ''

    geocoded_results = Geocoder.search(user_inputted_address).first unless Rails.env.test?

    unless geocoded_results.blank?
      lat = geocoded_results.geometry['location']['lat']
      lon = geocoded_results.geometry['location']['lng']
      street = geocoded_results.street_address
      city = geocoded_results.city
      state = geocoded_results.state_code
      zip = geocoded_results.postal_code
    end

    SuggestedLocation.create(region_id: region.id, name: params['location_name'], street: street || params['location_street'], city: city || params['location_city'], state: state || params['location_state'], zip: zip || params['location_zip'], phone: params['location_phone'], website: params['location_website'], location_type: location_type, operator: operator, comments: params['location_comments'], machines: params['location_machines'], lat: lat, lon: lon, user_inputted_address: user_inputted_address)
  end

  def send_new_region_notification(params)
    Pony.mail(
      to: Region.where('lower(name) = ?', 'portland').first.users.map(&:email),
      from: 'admin@pinballmap.com',
      subject: add_host_info_to_subject('PBM - New region suggestion'),
      body: <<END
Their Name: #{params['name']}\n
Their Email: #{params['email']}\n
Region Name: #{params['region_name']}\n
Region Comments: #{params['comments']}\n
END
    )
  end

  def send_admin_notification(params, region, user = nil)
    user_info = user ? "Username: #{user.username}\n\nSite Email: #{user.email}" : ''

    body = <<END
Their Name: #{params[:name]}\n
Their Email: #{params[:email]}\n
Message: #{params[:message]}\n
#{user_info}
END
    Pony.mail(
      to: region.users.map(&:email),
      bcc: User.all.select(&:is_super_admin).map(&:email),
      from: 'admin@pinballmap.com',
      subject: add_host_info_to_subject("PBM - Message from the #{region.full_name} region"),
      body: body
    )

    UserSubmission.create(region_id: region.id, submission_type: UserSubmission::CONTACT_US_TYPE, submission: body, user_id: user ? user.id : nil)
  end

  def send_app_comment(params, region)
    Pony.mail(
      to: 'pinballmap@posteo.org',
      bcc: User.all.select(&:is_super_admin).map(&:email),
      from: 'admin@pinballmap.com',
      subject: add_host_info_to_subject('PBM - App feedback'),
      body: <<END
OS: #{params['os']}\n
OS Version: #{params['os_version']}\n
Device Type: #{params['device_type']}\n
App Version: #{params['app_version']}\n
Region: #{region.name}\n
Their Name: #{params['name']}\n
Their Email: #{params['email']}\n
Message: #{params['message']}\n
END
    )
  end

  def return_response(data, root, includes = [], methods = [], http_status = 200)
    render json: { root => data.as_json(include: includes, methods: methods, root: false) }, status: http_status
  end

  def allow_cors
    headers['Access-Control-Allow-Origin'] = '*'
    headers['Access-Control-Request-Method'] = '*'
    headers['Access-Control-Allow-Methods'] = %w[GET POST PUT DELETE OPTIONS].join(',')
    headers['Access-Control-Allow-Headers'] = %w[Origin Accept Content-Type X-Requested-With X-CSRF-Token].join(',')

    head(:ok) if request.request_method == 'OPTIONS'
  end

  private

  def after_sign_out_path_for(*)
    request.referrer =~ /admin/ ? root_path : request.referrer
  end

  def store_location
    return unless request.get?
    if request.path != '/users/login' &&
       request.path != '/users/join' &&
       request.path != '/users/password/new' &&
       request.path != '/users/password/edit' &&
       request.path != '/users/confirmation' &&
       request.path != '/users/logout' &&
       !request.xhr?
      session[:previous_url] = request.fullpath
    end
  end

  def after_sign_in_path_for(*)
    session[:previous_url] || root_path
  end

  def flash_message
    %i[error warning notice].each do |type|
      return flash[type] unless flash[type].blank?
    end
  end

  def flash_type
    %i[error warning notice].each do |type|
      return type unless flash[type].blank?
    end
  end

  def mobile_device?
    if session[:mobile_param]
      session[:mobile_param] == '1'
    else
      (request.user_agent =~ /Mobile|webOS/) && (request.user_agent !~ /iPad/)
    end
  end

  helper_method :mobile_device?

  protected

  def default_url_options
    if Rails.env.production?
      { host: 'www.pinballmap.com', protocol: 'https' }
    else
      { protocol: 'http' }
    end
  end

  def configure_permitted_parameters
    devise_parameter_sanitizer.for(:sign_up) { |u| u.permit(:username, :email, :password, :password_confirmation, :remember_me) }
    devise_parameter_sanitizer.for(:sign_in) { |u| u.permit(:login, :username, :email, :password, :remember_me) }
    devise_parameter_sanitizer.for(:account_update) { |u| u.permit(:username, :email, :password, :password_confirmation, :current_password) }
  end

  def detect_region
    @region = Region.find_by_name(params[:region].downcase) if params[:region] && (params[:region].is_a? String)
  end

  def set_current_user
    Authorization.current_user = current_user
  end
end
