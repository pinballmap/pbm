require 'pony'

class ApplicationController < ActionController::Base
  FILTERING_REQUIRED_MSG = 'Filtering is required for this action. Please provide a filter when using this endpoint.'.freeze
  AUTH_REQUIRED_MSG = 'Authentication is required for this action. If you are using the app, you may need to confirm your account (see the email from us) or log out and back in.'.freeze

  acts_as_token_authentication_handler_for User, fallback: :none

  protect_from_forgery prepend: true
  before_action :configure_permitted_parameters, if: :devise_controller?
  before_action :detect_region
  after_action :flash_to_headers, :store_location

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
    server_name = request.host.match?(/pinballmapstaging/) ? '(STAGING) ' : ''

    server_name + subject
  end

  def send_new_machine_notification(machine, location, user)
    render js: 'show_new_machine_message();'

    user_info = user ? " by #{user.username} (#{user.email})" : ''

    Pony.mail(
      to: Region.find_by_name('portland').users.map(&:email),
      from: 'admin@pinballmap.com',
      subject: add_host_info_to_subject('PBM - New machine name'),
      body: [machine.name, location.name, "(entered from #{request.remote_ip} via #{request.user_agent}#{user_info})"].join("\n")
    )
  end

  def send_new_location_notification(params, region, user = nil)
    user_info = user ? " by #{user.username} (#{user.email})" : ''

    location_type = params['location_type']&.is_a?(Integer) || params['location_type']&.match?(/^[0-9]+$/) ? LocationType.find(params['location_type']) : LocationType.find_by_name(params['location_type'])
    operator = params['location_operator']&.is_a?(Integer) || params['location_operator']&.match?(/^[0-9]+$/) ? Operator.find(params['location_operator']) : Operator.find_by_name(params['location_operator'])
    zone = params['location_zone']&.is_a?(Integer) || params['location_zone']&.match?(/^[0-9]+$/) ? Zone.find(params['location_zone']) : Zone.find_by_name(params['location_zone'])

    user_inputted_address = [params['location_street'], params['location_city'], params['location_state'], params['location_zip']].join(', ')

    (geocoded_results, lat, lon, street, city, state, zip) = ''

    geocoded_results = Geocoder.search(user_inputted_address).first unless Rails.env.test?

    street_address = [geocoded_results.address_components_of_type(:street_number).dig(0, 'long_name'), geocoded_results.address_components_of_type(:route).dig(0, 'short_name')].compact.join(' ') unless Rails.env.test?

    if geocoded_results.present?
      lat, lon = geocoded_results.coordinates
      street = street_address
      city = geocoded_results.city
      state = geocoded_results.state_code
      zip = geocoded_results.postal_code
    end

    region = region unless params[:region_id].blank? || region.blank?

    if region.blank?
      if geocoded_results.present?
        region = Region.near([lat, lon], :effective_radius).first
      else
        region = Region.near([params[:lat], params[:lon]], :effective_radius).first
      end
    end

    body = <<BODY
    Dear Admin: You can approve this location with the click of a button at #{request.protocol}#{request.host_with_port}#{rails_admin_path}/suggested_location\n\nClick the "(i)" to the right, and then click the big "APPROVE LOCATION" button at the top.\n\nBut first, check that the location is not already on the map, add any missing fields (like Type, Phone, and Website), confirm the address via https://maps.google.com, and make sure it's a public venue. Thanks!!\n
Location Name: #{params['location_name']}\n
Street: #{params['location_street']}\n
City: #{params['location_city']}\n
State: #{params['location_state']}\n
Zip: #{params['location_zip']}\n
Country: #{params['location_country']}\n
Phone: #{params['location_phone']}\n
Website: #{params['location_website']}\n
Type: #{location_type ? location_type.name : ''}\n
Operator: #{operator ? operator.name : ''}\n
Zone: #{zone ? zone.name : ''}\n
Comments: #{params['location_comments']}\n
Machines: #{params['location_machines']}\n
(entered from #{request.remote_ip} via #{request.user_agent}#{user_info})\n
BODY
    Pony.mail(
      to: region ? region.users.map(&:email) : User.all.select(&:is_super_admin).map(&:email),
      bcc: User.all.select(&:is_super_admin).map(&:email),
      from: 'admin@pinballmap.com',
      subject: add_host_info_to_subject("PBM - New location suggested for#{region ? ' the ' + region.name : ''} pinball map"),
      body: body
    )

    UserSubmission.create(region_id: region ? region.id : nil, submission_type: UserSubmission::SUGGEST_LOCATION_TYPE, submission: body, user_id: user ? user.id : nil)

    SuggestedLocation.create(region_id: region ? region.id : nil, name: params['location_name'], street: street || params['location_street'], city: city || params['location_city'], state: state || params['location_state'], zip: zip || params['location_zip'], country: params['location_country'], phone: params['location_phone'], website: params['location_website'], location_type: location_type, operator: operator, zone: zone, comments: params['location_comments'], machines: params['location_machines'], lat: lat, lon: lon, user_inputted_address: user_inputted_address)
  end

  def send_new_region_notification(params)
    Pony.mail(
      to: Region.where('lower(name) = ?', 'portland').first.users.map(&:email),
      from: 'admin@pinballmap.com',
      subject: add_host_info_to_subject('PBM - New region suggestion'),
      body: <<BODY
Their Name: #{params['name']}\n
Their Email: #{params['email']}\n
Region Name: #{params['region_name']}\n
Region Comments: #{params['comments']}\n
(entered from #{request.remote_ip} via #{request.user_agent})\n
BODY
    )
  end

  def send_admin_notification(params, region, user = nil)
    user_info = user ? "Username: #{user.username}\n\nSite Email: #{user.email}" : ''

    body = <<BODY
Their Name: #{params[:name]}\n
Their Email: #{params[:email]}\n
Message: #{params[:message]}\n
#{user_info}\n
(entered from #{request.remote_ip} via #{request.user_agent})\n
BODY
    to_users = region.nil? ? User.all.select(&:is_super_admin).map(&:email) : region.users.map(&:email)
    Pony.mail(
      to: to_users,
      cc: region.nil? ? [] : User.all.select(&:is_super_admin).map(&:email),
      from: 'admin@pinballmap.com',
      subject: add_host_info_to_subject(region.nil? ? 'PBM - Message' : "PBM - Message from the #{region.full_name} region"),
      body: body
    )

    UserSubmission.create(region_id: region.nil? ? nil : region.id, submission_type: UserSubmission::CONTACT_US_TYPE, submission: body, user_id: user ? user.id : nil)
  end

  def send_app_comment(params, region)
    Pony.mail(
      to: 'map@pinballmap.com',
      cc: User.all.select(&:is_super_admin).map(&:email),
      from: 'admin@pinballmap.com',
      subject: add_host_info_to_subject('PBM - App feedback'),
      body: <<BODY
OS: #{params['os']}\n
OS Version: #{params['os_version']}\n
Device Type: #{params['device_type']}\n
App Version: #{params['app_version']}\n
Region: #{region.name}\n
Their Name: #{params['name']}\n
Their Email: #{params['email']}\n
Message: #{params['message']}\n
BODY
    )
  end

  def return_response(data, root, includes = [], methods = [], http_status = 200, except = [])
    json_data = data.as_json(include: includes, methods: methods, root: false, except: except)

    render json: root.nil? ? json_data : { root => json_data }, status: http_status
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
    request.referrer.match?(/admin/) ? root_path : request.referrer
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
    devise_parameter_sanitizer.permit(:sign_up) { |u| u.permit(:username, :email, :password, :password_confirmation, :remember_me, :security_test) }
    devise_parameter_sanitizer.permit(:sign_in) { |u| u.permit(:login, :username, :email, :password, :remember_me) }
    devise_parameter_sanitizer.permit(:account_update) { |u| u.permit(:username, :email, :password, :password_confirmation, :current_password) }
  end

  def detect_region
    @region = Region.find_by_name(params[:region].downcase) if params[:region] && (params[:region].is_a? String)
  end
end
