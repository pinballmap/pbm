class PagesController < ApplicationController
  respond_to :xml, :json, :html, :js, :rss
  has_scope :by_location_name, :by_location_id, :by_machine_name, :by_machine_id, :by_machine_single_id, :by_at_least_n_machines, :by_type_id, :by_operator_id, :user_faved, :by_city_name, :by_state_name

  def params
    request.parameters
  end

  def map_location_data
    @locations = []

    if params[:address].blank? && params[:by_machine_id].blank? && params[:by_machine_single_id].blank? && params[:by_machine_name].blank? && params[:by_location_name].blank? && params[:user_faved].blank? && params[:by_city_name].blank? && params[:by_state_name].blank?
      @locations = []
    else
      params.delete(:by_machine_name) unless params[:by_machine_id].blank? && params[:by_machine_single_id].blank?

      @lat, @lon = ''
      if !params[:address].blank? || !params[:by_city_name].blank?
        if Rails.env.test?
          # hardcode a PDX lat/lon during tests
          @lat = 45.590502800000
          @lon = -122.754940100000
        elsif !params[:by_city_name].blank?
          @locations = apply_scopes(Location).order('locations.name').includes(:location_machine_xrefs, :machines, :region, :location_type)
        else
          results = Geocoder.search(params[:address])
          results = Geocoder.search(params[:address], lookup: :here) if results.blank?
          results = Geocoder.search(params[:address], lookup: :nominatim) if results.blank?
          @lat, @lon = results.first.coordinates
        end
      end
      @near_distance = 15
      while @locations.blank? && @near_distance < 600
        @locations = apply_scopes(params[:address].blank? ? Location : Location.near([@lat, @lon], @near_distance)).order('locations.name').includes(:location_machine_xrefs, :machines, :region, :location_type)
        @near_distance += 100
      end
    end

    @location_data = LocationsController.locations_javascript_data(@locations)

    render partial: 'locations/locations', layout: false
  end

  def operator_location_data
    @locations = Location.where(operator_id: params[:by_operator_id]).includes(:location_type, :machines, :region)

    @location_data = LocationsController.locations_javascript_data(@locations)

    render partial: 'locations/locations', layout: false
  end

  def map
    user = current_user.nil? ? nil : current_user

    params[:user_faved] = user.id if user && !params[:user_faved].blank?

    if !params[:by_location_id].blank? && (loc = Location.where(id: params[:by_location_id]).first)
      @title_params[:title] = loc.name
      location_type = loc.location_type.name + ' - ' unless loc.location_type.nil?
      machine_list = ' - ' + loc.machine_names_first_no_year.join(', ') unless loc.machine_names_first_no_year.empty?
      @title_params[:title_meta] = loc.full_street_address + ' - ' + location_type.to_s + loc.num_machines_sentence + machine_list.to_s
    end

    @big_locations_sample = Location.select('name, random() as r').joins(:location_machine_xrefs).group('id').having('count(location_machine_xrefs)>9').order('r').first
    @location_placeholder = @big_locations_sample.nil? ? 'e.g. Ground Kontrol' : 'e.g. ' + @big_locations_sample.name

    @machine_sample = Machine.select('name, random() as r').order('r').limit(1).first
    @machine_placeholder = @machine_sample.nil? ? 'e.g. Lord of the Rings' : 'e.g. ' + @machine_sample.name

    @big_cities_sample = Location.select(%i[city state], 'random() as r').having('count(city)>9').where.not(state: [nil, '']).group('city', 'state').order('r').limit(1).first
    @big_cities_placeholder = @big_cities_sample.nil? ? 'e.g. Portland, OR' : 'e.g. ' + @big_cities_sample.city + ', ' + @big_cities_sample.state
  end

  def region
    @locations = Location.where('region_id = ?', @region.id).includes(:location_type, :operator)
    @location_count = @locations.count
    @lmx_count = @region.machines_count

    if !params[:by_location_id].blank? && (loc = Location.where(id: params[:by_location_id]).first)
      @title_params[:title] = loc.name
      location_type = loc.location_type.name + ' - ' unless loc.location_type.nil?
      machine_list = ' - ' + loc.machine_names_first_no_year.join(', ') unless loc.machine_names_first_no_year.empty?
      @title_params[:title_meta] = loc.full_street_address + ' - ' + location_type.to_s + loc.num_machines_sentence + machine_list.to_s
    end

    cities = {}
    location_types = {}
    operators = {}

    @locations.each do |l|
      location_types[l.location_type_id] = l if l.location_type_id

      cities[l.city] = l

      operators[l.operator_id] = l if l.operator_id
    end

    @search_options = {
      'type' => {
        'id'   => 'id',
        'name' => 'name',
        'search_collection' => location_types.values.map(&:location_type).sort_by(&:name)
      },
      'location' => {
        'id'   => 'id',
        'name' => 'name_and_city',
        'search_collection' => @locations.sort_by(&:massaged_name),
        'autocomplete' => 1
      },
      'machine' => {
        'id'   => 'id',
        'name' => 'name_and_year',
        'search_collection' => @region.machines.sort_by(&:massaged_name),
        'autocomplete' => 1
      },
      'zone' => {
        'id'   => 'id',
        'name' => 'name',
        'search_collection' => Zone.where('region_id = ?', @region.id).order('name')
      },
      'operator' => {
        'id'   => 'id',
        'name' => 'name',
        'search_collection' => operators.values.map(&:operator).sort_by(&:name)
      },
      'city' => {
        'id'   => 'city',
        'name' => 'city',
        'search_collection' => cities.values.sort_by(&:city)
      }
    }

    render "#{@region.name}/region" if lookup_context.find_all("#{@region.name}/region").any?
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
