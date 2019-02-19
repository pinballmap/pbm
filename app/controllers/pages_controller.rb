require 'pony'

class PagesController < ApplicationController
  respond_to :xml, :json, :html, :js, :rss
  has_scope :by_location_name, :by_location_id, :by_machine_name, :by_machine_id, :user_faved

  def params
    request.parameters
  end

  def regionless_location_data
    @locations = []

    if params[:address].blank? && params[:by_machine_id].blank? && params[:by_machine_name].blank? && params[:by_location_name].blank? && params[:user_faved].blank?
      @locations = []
    else
      params.delete(:by_machine_name) unless params[:by_machine_id].blank?

      @lat, @lon = ''
      unless params[:address].blank?
        results = Geocoder.search(params[:address])

        (@lat, @lon) = results.first.coordinates
      end

      @locations = apply_scopes(params[:address].blank? ? Location : Location.near(params[:address], 5)).order('locations.name').includes(:location_machine_xrefs, :machines, :location_picture_xrefs, :region, :location_type)
    end

    @location_data = LocationsController.locations_javascript_data(@locations)

    render partial: 'locations/locations', layout: false
  end

  def regionless
    user = current_user.nil? ? nil : current_user

    params[:user_faved] = user.id if user && !params[:user_faved].blank?
  end

  def region
    @locations = Location.where('region_id = ?', @region.id).includes(:location_type)
    @location_count = @locations.count
    @lmx_count = @region.machines_count

    cities = {}
    location_types = {}

    @locations.each do |l|
      location_types[l.location_type_id] = l if l.location_type_id

      cities[l.city] = l
    end

    @search_options = {
      'type' => {
        'id'   => 'id',
        'name' => 'name',
        'search_collection' => location_types.values.map(&:location_type).sort_by(&:name)
      },
      'location' => {
        'id'   => 'id',
        'name' => 'name',
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
        'search_collection' => Operator.where('operators.region_id = ?', @region.id).joins(:locations).group('operators.id').order('name')
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
    return if params['contact_msg'].nil? || params['contact_msg'].empty?

    user = current_user.nil? ? nil : current_user

    if user
      flash.now[:alert] = 'Thanks for contacting us!'
      send_admin_notification({ email: params['contact_email'], name: params['contact_name'], message: params['contact_msg'] }, @region, user)
    else
      if verify_recaptcha
        flash.now[:alert] = 'Thanks for contacting us!'
        send_admin_notification({ email: params['contact_email'], name: params['contact_name'], message: params['contact_msg'] }, @region, user)
      else
        flash.now[:alert] = 'Your captcha entering skills have failed you. Please go back and try again.'
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
    flash.now[:alert] = "Thanks for entering that location. We'll get it in the system as soon as possible."

    user = current_user.nil? ? nil : current_user
    send_new_location_notification(params, @region, user)
  end

  def suggest_new_location
    @operators = []
    @zones = []
    @states = []

    if @region
      @states = Location.where(['region_id = ?', @region.id]).map(&:state).uniq.sort
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
    @locations = Location.where('region_id = ?', @region.id)
    @location_count = @locations.count
    @lmx_count = @region.machines_count
  end

  def home
    if ENV['TWITTER_CONSUMER_KEY'] && ENV['TWITTER_CONSUMER_SECRET'] && ENV['TWITTER_OAUTH_TOKEN_SECRET'] && ENV['TWITTER_OAUTH_TOKEN']
      begin
        client = Twitter::REST::Client.new do |config|
          config.consumer_key = ENV['TWITTER_CONSUMER_KEY']
          config.consumer_secret = ENV['TWITTER_CONSUMER_SECRET']
          config.access_token = ENV['TWITTER_OAUTH_TOKEN']
          config.access_token_secret = ENV['TWITTER_OAUTH_TOKEN_SECRET']
        end
        @tweets = client.user_timeline('pinballmapcom', count: 5)
      rescue Twitter::Error
        @tweets = []
      end
    else
      @tweets = []
    end

    @machine_and_location_count_by_region = Region.machine_and_location_count_by_region
    @all_regions = Region.order(:state, :full_name)
    @region_data = regions_javascript_data(@all_regions, @machine_and_location_count_by_region)
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
