require 'pony'

class PagesController < ApplicationController
  respond_to :xml, :json, :html, :js, :rss
  has_scope :by_location_name, :by_location_id, :by_machine_name, :by_machine_id, :user_faved

  def params
    request.parameters
  end

  def map_location_data
    @locations = []

    if params[:address].blank? && params[:by_machine_id].blank? && params[:by_machine_name].blank? && params[:by_location_name].blank? && params[:user_faved].blank?
      @locations = []
    else
      params.delete(:by_machine_name) unless params[:by_machine_id].blank?

      @lat, @lon = ''
      unless params[:address].blank?
        if Rails.env.test?
          # hardcode a PDX lat/lon during tests
          @lat = 45.590502800000
          @lon = -122.754940100000
        else
          results = Geocoder.search(params[:address])
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

  def map
    user = current_user.nil? ? nil : current_user

    params[:user_faved] = user.id if user && !params[:user_faved].blank?

    @big_locations = Location.joins(:location_machine_xrefs).group('id').having('count(location_machine_xrefs)>9')
    @big_locations_sample = @big_locations.sample
    @location_placeholder = @big_locations_sample.nil? ? 'e.g. Ground Kontrol' : 'e.g. ' + @big_locations_sample.name

    @machine_list = Machine.all
    @machine_sample = @machine_list.sample
    @machine_placeholder = @machine_sample.nil? ? 'e.g. Lord of the Rings' : 'e.g. ' + @machine_sample.name

    @big_cities = Location.select(%i[city state]).having('count(city)>9', 'count(state)>0').group('city', 'state')
    @big_cities_sample = @big_cities.sample
    @big_cities_placeholder = @big_cities_sample.nil? ? 'e.g. Portland, OR' : 'e.g. ' + @big_cities_sample.city + ', ' + @big_cities_sample.state
  end

  def region
    @locations = Location.where('region_id = ?', @region.id).includes(:location_type, :operator)
    @location_count = @locations.count
    @lmx_count = @region.machines_count

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
    return if params['contact_msg'].nil? || params['contact_msg'].empty? || params['contact_msg'].match?(/vape/) || params['contact_msg'].match?(/seo/)

    user = current_user.nil? ? nil : current_user
    @answers = %w[pinball Pinball PINBALL]

    if user
      flash.now[:alert] = 'Thanks for contacting us!'
      send_admin_notification({ email: params['contact_email'], name: params['contact_name'], message: params['contact_msg'] }, @region, user)
    else
      if @answers.any? { |w| params['security_test'][w] }
        flash.now[:alert] = 'Thanks for contacting us!'
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
    flash.now[:alert] = "Thanks for your submission! We'll review and add it soon. Be patient!"

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
    robots = File.read(Rails.root + 'public/robots.txt')
    render plain: robots
  end

  def apple_app_site_association
    aasa = File.read(Rails.root + '.well-known/apple-app-site-association')
    render json: aasa
  end

  def app; end

  def app_support; end

  def privacy; end

  def store; end

  def faq; end

  def donate; end

  def profile; end

  def contact
    redirect_to about_path
  end

  def flier
    @locations = !@region.nil? ? Location.where('region_id = ?', @region.id) : ''
    @location_count = !@region.nil? ? @locations.count : ''
    @lmx_count = !@region.nil? ? @region.machines_count : ''
  end

  def home
    @machine_and_location_count_by_region = Region.machine_and_location_count_by_region
    @all_regions = Region.order(:state, :full_name)
    @region_data = regions_javascript_data(@all_regions, @machine_and_location_count_by_region)

    @last_updated_time = Location.maximum(:updated_at)
  end

  def regions_javascript_data(regions, machine_and_location_count_by_region)
    ids = []
    lats = []
    lons = []
    contents = []

    regions.each do |r|
      ids      << r.id
      lats     << r.lat
      lons     << r.lon
      contents << r.content_for_infowindow(machine_and_location_count_by_region[r.id]['locations_count'], machine_and_location_count_by_region[r.id]['machines_count'])
    end

    [ids, lats, lons, contents]
  end

  def inspire_profile
    user = current_user.nil? ? nil : current_user

    redirect_to profile_user_path(user.id) if user
  end
end
