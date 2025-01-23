class PagesController < ApplicationController
  respond_to :xml, :json, :html, :js, :rss

  def map
    user = current_user.nil? ? nil : current_user

    params[:user_faved] = user.id if user && !params[:user_faved].blank?

    if !params[:by_location_id].blank? && (loc = Location.where(id: params[:by_location_id]).first)
      @title_params[:title] = "#{loc.name} - Pinball Map"
      machine_length = ' - ' + loc.machines.length.to_s + ' ' + 'machine'.pluralize(loc.machines.length) unless loc.machines.empty?
      machine_list = ' - ' + loc.machine_names_first_no_year.join(', ') unless loc.machine_names_first_no_year.empty?
      @title_params[:title_meta] = "#{loc.name} on Pinball Map! " + loc.full_street_address + machine_length.to_s + machine_list.to_s
    end

    @big_locations_sample = Location.select('name, random() as r').joins(:location_machine_xrefs).group('id').having('count(location_machine_xrefs)>9').order('r').first
    @location_placeholder = @big_locations_sample.nil? ? 'e.g. Ground Kontrol' : 'e.g. ' + @big_locations_sample.name

    @machine_sample = Machine.select('name, random() as r').order('r').limit(1).first
    @machine_placeholder = @machine_sample.nil? ? 'e.g. Lord of the Rings' : 'e.g. ' + @machine_sample.name

    @big_cities_sample = Location.select(%i[city state], 'random() as r').having('count(city)>9').where.not(state: [nil, '']).group('city', 'state').order('r').limit(1).first
    @big_cities_placeholder = @big_cities_sample.nil? ? 'e.g. Portland, OR' : 'e.g. ' + @big_cities_sample.city + ', ' + @big_cities_sample.state
  end

  def contact_sent
    user = current_user.nil? ? nil : current_user
    return if params['contact_msg'].blank? || (!user && params['contact_email'].blank?) || params['contact_msg'].match?(/vape/) || params['contact_msg'].match?(/seo/) || params['contact_msg'].match?(/Ezoic/)

    if user
      @contact_thanks = 'Thanks for contacting us! If you are expecting a reply, check your spam folder or whitelist admin@pinballmap.com'.freeze
      send_admin_notification({ email: params['contact_email'], name: params['contact_name'], message: params['contact_msg'] }, @region, user)
    else
      if params['security_test'] =~ /pinball/i
        @contact_thanks = 'Thanks for contacting us! If you are expecting a reply, check your spam folder or whitelist admin@pinballmap.com'.freeze
        send_admin_notification({ email: params['contact_email'], name: params['contact_name'], message: params['contact_msg'] }, @region, user)
      else
        flash.now[:alert] = 'You failed the security test. Please go back and try again.'
      end
    end
  end

  def about
    @links = {}
    @region.region_link_xrefs.each do |rlx|
      (@links[rlx.category && !rlx.category.blank? ? rlx.category : 'Links'] ||= []) << rlx
    end

    @top_machines = LocationMachineXref
                    .includes(:machine)
                    .region(@region.name)
                    .select('machine_id, count(*) as machine_count')
                    .group(:machine_id)
                    .order('machine_count desc')
                    .limit(10)

    render "#{@region.name}/about" if lookup_context.find_all("#{@region.name}/about").any?
  end

  def links
    redirect_to about_path
  end

  def high_rollers
    @high_rollers = @region.n_high_rollers(10)
  end

  def submitted_new_location
    @submit_thanks = "Thanks for your submission! Please allow us 0-7 days to review and add it. No need to re-submit it or remind us (unless it's opening day!). Note that you usually won't get a message from us confirming that it's been added.".freeze

    user = current_user.nil? ? nil : current_user
    send_new_location_notification(params, @region, user)
  end

  def suggest_new_location
    @operators = []
    @zones = []
    @states = []

    if @region
      @states = Location.where(['region_id = ?', @region.id]).where.not(state: [nil, '']).map(&:state).uniq.sort
      @states.unshift('')

      @operators = Operator.where(['region_id = ?', @region.id]).map(&:name).uniq.sort
      @operators.unshift('')

      @zones = Zone.where(['region_id = ?', @region.id]).map(&:name).uniq.sort
      @zones.unshift('')
    end

    @location_types = LocationType.all.map(&:name).uniq.sort
    @location_types.unshift('')
  end

  def robots
    robots = File.read(Rails.root.join('config', "robots.#{Rails.env}.txt"))
    render plain: robots
  end

  def apple_app_site_association
    aasa = File.read(Rails.root + '.well-known/apple-app-site-association')
    render json: aasa
  end

  def app; end

  def privacy; end

  def store; end

  def faq; end

  def donate; end

  def profile; end

  def set_activities
    submission_type = params[:submission_type].blank? ? %w[new_lmx remove_machine new_condition new_msx confirm_location] : params[:submission_type]

    if @region && params[:submission_type]
      @pagy, @recent_activity = pagy(UserSubmission.where(submission_type: submission_type, region_id: @region.id, created_at: '2019-05-03T07:00:00.00-07:00'..Date.today.end_of_day).order('created_at DESC'), params: { submission_type: submission_type })
    elsif @region
      @pagy, @recent_activity = pagy(UserSubmission.where(submission_type: submission_type, region_id: @region.id, created_at: '2019-05-03T07:00:00.00-07:00'..Date.today.end_of_day).order('created_at DESC'))
    elsif params[:submission_type]
      @pagy, @recent_activity = pagy(UserSubmission.where(submission_type: submission_type, created_at: '2019-05-03T07:00:00.00-07:00'..Date.today.end_of_day).order('created_at DESC'), params: { submission_type: submission_type })
    else
      @pagy, @recent_activity = pagy(UserSubmission.where(submission_type: submission_type, created_at: '2019-05-03T07:00:00.00-07:00'..Date.today.end_of_day).order('created_at DESC'))
    end

    if @region
      @region_fullname = 'the ' + @region.full_name
      @region_name = @region.name
    else
      @region_fullname = ''
      @region_name = 'map'
    end
    respond_to do |format|
      format.html
    end
  end

  def recent_activity
    set_activities
    case request.request_method
    when 'GET'
      render 'pages/activity'
    when 'POST'
      render partial: 'pages/render_activity', object: @recent_activity
    else
      p "unknown request_method: #{request.request_method}"
    end
  end

  def contact
    redirect_to about_path
  end

  def flier; end

  def home
    @locations_count_total = Location.all.count
    @machines_count_total = LocationMachineXref.all.count
    @all_regions = Region.order(:state, :full_name)

    @last_updated_time = Location.maximum(:updated_at)
  end

  def inspire_profile
    user = current_user.nil? ? nil : current_user

    redirect_to profile_user_path(user.id) if user
  end
end
