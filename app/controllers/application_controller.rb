class ApplicationController < ActionController::Base
  FILTERING_REQUIRED_MSG = "Filtering is required for this action. Please provide a filter when using this endpoint.".freeze
  AUTH_REQUIRED_MSG = "Authentication is required for this action. If you are using the app, you may need to confirm your account (see the email from us) or log out and back in.".freeze
  rate_limit to: 140, within: 20.minutes, if: lambda { |req| req.bot? }

  include Pagy::Backend

  def append_info_to_payload(payload)
    if Rails.env.production?
      super
      payload[:user_id] = current_user&.id
      payload[:bot_or_not] = browser.bot? ? "IsBot" : "NotBot"
    end
  end

  def no_route
    render file: Rails.public_path.join("404.html"), status: :not_found, layout: false
  end

  def bot?
    browser.bot?
  end

  acts_as_token_authentication_handler_for User, fallback: :none

  protect_from_forgery prepend: true
  before_action :configure_permitted_parameters, if: :devise_controller?
  before_action :detect_region
  before_action { @title_params = {} } # default to an un-set title
  after_action :flash_to_headers, :store_location

  rescue_from ActionView::MissingTemplate do
  end

  rescue_from CanCan::AccessDenied do |exception|
    redirect_to "/users/login", alert: exception.message
  end

  def flash_to_headers
    return unless request.xhr?

    response.headers["X-Message"] = flash_message
    response.headers["X-Message-Type"] = flash_type.to_s

    flash.discard
  end

  def add_host_info_to_subject(subject)
    server_name = request.host.match?(/pbmstaging/) ? "(STAGING) " : ""

    server_name + subject
  end

  def send_new_location_notification(params, region, user = nil)
    user_info = user ? " by #{user.username} (#{user.email})" : ""

    location_type = params["location_type"]&.is_a?(Integer) || params["location_type"]&.match?(/^[0-9]+$/) ? LocationType.find(params["location_type"]) : LocationType.find_by_name(params["location_type"])
    operator = params["location_operator"]&.is_a?(Integer) || params["location_operator"]&.match?(/^[0-9]+$/) ? Operator.find(params["location_operator"]) : Operator.find_by_name(params["location_operator"])
    zone = params["location_zone"]&.is_a?(Integer) || params["location_zone"]&.match?(/^[0-9]+$/) ? Zone.find(params["location_zone"]) : Zone.find_by_name(params["location_zone"])

    user_inputted_address = [ params["location_street"], params["location_city"], params["location_state"], params["location_zip"] ].join(", ")

    (geocoded_results, lat, lon, street, city, state, zip) = ""

    geocoded_results = Geocoder.search(user_inputted_address).first unless Rails.env.test?

    street_address = geocoded_results.formatted_address.split(",")[0] unless Rails.env.test?

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
        region = Region.near([ lat, lon ], :effective_radius).first
      else
        region = Region.near([ params[:lat], params[:lon] ], :effective_radius).first
      end
    end

    machine_name_list = ""
    machine_id_list = ""
    if !params["location_machines_ids"].nil?
      params["location_machines_ids"]&.each do |machine_id|
        machine = Machine.find_by(id: machine_id)
        machine_name_list = machine_name_list + machine.name_and_year + ", "
      end
      machine_id_list = params["location_machines_ids"]
    else
      machine_name_list = params["location_machines"]
      machine_id_list = params["location_machines"]
    end

    body = "Location Name: #{params['location_name']} Street: #{params['location_street']} City: #{params['location_city']} State: #{params['location_state']} Zip: #{params['location_zip']} Country: #{params['location_country']} Phone: #{params['location_phone']} Website: #{params['location_website']} Type: #{location_type ? location_type.name : ''} Operator: #{operator ? operator.name : ''} Zone: #{zone ? zone.name : ''} Comments: #{params['location_comments']} Machines: #{machine_name_list} (entered from #{request.remote_ip} via #{request.headers['AppVersion']} #{request.user_agent}#{user_info})"

    AdminMailer.with(to_users: region ? region.users.map(&:email) : User.all.select(&:is_super_admin).map(&:email), cc_users: User.all.select(&:is_super_admin).map(&:email), subject: add_host_info_to_subject("Pinball Map - New location#{region ? ' (' + region.full_name + ')' : ''} - #{params['location_name']}"), location_name: params["location_name"], location_street: params["location_street"], location_city: params["location_city"], location_state: params["location_state"], location_zip: params["location_zip"], location_country: params["location_country"], location_phone: params["location_phone"], location_website: params["location_website"], location_type: location_type ? location_type.name : "", operator: operator ? operator.name : "", zone: zone ? zone.name : "", location_comments: params["location_comments"], location_machines: machine_name_list, remote_ip: request.remote_ip, headers: request.headers["AppVersion"], user_agent: request.user_agent, user_info: user_info).send_new_location_notification.deliver_later

    UserSubmission.create(region_id: region&.id, submission_type: UserSubmission::SUGGEST_LOCATION_TYPE, submission: body, user_id: user&.id)
    User.increment_counter(:num_locations_suggested, user&.id)

    SuggestedLocation.create(region_id: region&.id, name: params["location_name"], street: street || params["location_street"], city: city || params["location_city"], state: state || params["location_state"], zip: zip || params["location_zip"], country: params["location_country"], phone: params["location_phone"], website: params["location_website"], location_type: location_type, operator: operator, zone: zone, comments: params["location_comments"], machines: machine_id_list, lat: lat, lon: lon, user_inputted_address: user_inputted_address, user_id: user&.id)
  end

  def send_admin_notification(params, region, user = nil)
    sender_name = user&.username || params[:name]
    sender_string = user&.id ? "Username: #{user.username} User Email: #{user.email}" : "Their Name: #{params[:name]} Their Email: #{params[:email]}"
    body = "#{sender_string} Message: #{params[:message]} (entered from #{request.remote_ip} via #{request.headers['AppVersion']} #{request.user_agent})"

    AdminMailer.with(name: params[:name], email: params[:email], message: params[:message], user_name: user&.username, user_email: user&.email, to_users: region.nil? ? User.all.select(&:is_super_admin).map(&:email) : region.users.map(&:email), cc_users: region.nil? ? [] : User.all.select(&:is_super_admin).map(&:email), subject: add_host_info_to_subject(region.nil? ? "Pinball Map - Message from #{sender_name}" : "Pinball Map - Message (#{region.full_name}) from #{sender_name}"), remote_ip: request.remote_ip, headers: request.headers["AppVersion"], user_agent: request.user_agent).send_admin_notification.deliver_later

    UserSubmission.create(region_id: region&.id, submission_type: UserSubmission::CONTACT_US_TYPE, submission: body, user_id: user&.id)
  end

  def return_response(data, root, includes = [], methods = [], http_status = 200, except = [])
    json_data = data.as_json(include: includes, methods: methods, root: false, except: except)

    render json: root.nil? ? json_data : { root => json_data }, status: http_status
  end

  def allow_cors
    headers["Access-Control-Allow-Origin"] = "*"
    headers["Access-Control-Request-Method"] = "*"
    headers["Access-Control-Allow-Methods"] = %w[GET POST PUT DELETE OPTIONS].join(",")
    headers["Access-Control-Allow-Headers"] = %w[Origin Accept Content-Type X-Requested-With X-CSRF-Token].join(",")

    head(:ok) if request.request_method == "OPTIONS"
  end

  private

  def after_sign_out_path_for(*)
    request.referrer.match?(/admin/) ? root_path : request.referrer
  end

  def store_location
    return unless request.get?

    if request.path != "/users/login" &&
       request.path != "/users/join" &&
       request.path != "/users/password/new" &&
       request.path != "/users/password/edit" &&
       request.path != "/users/confirmation" &&
       request.path != "/users/logout" &&
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
      session[:mobile_param] == "1"
    else
      (request.user_agent =~ /Mobile|webOS/) && (request.user_agent !~ /iPad/)
    end
  end

  helper_method :mobile_device?

  def is_bot?
    browser.bot?
  end

  helper_method :is_bot?

  protected

  def default_url_options
    if Rails.env.production?
      { host: "www.pinballmap.com", protocol: "https" }
    else
      { protocol: "http" }
    end
  end

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up) { |u| u.permit(:username, :email, :password, :password_confirmation, :remember_me) }
    devise_parameter_sanitizer.permit(:sign_in) { |u| u.permit(:login, :username, :email, :password, :remember_me) }
    devise_parameter_sanitizer.permit(:account_update) { |u| u.permit(:username, :email, :password, :password_confirmation, :current_password) }
  end

  def detect_region
    @region = Region.find_by_name(params[:region].downcase) if params[:region]&.is_a? String
  end
end
