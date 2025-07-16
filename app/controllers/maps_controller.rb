class MapsController < ApplicationController
  respond_to :html, only: %i[get_bounds]
  has_scope :by_location_name, :by_location_id, :by_machine_id, :by_machine_single_id, :by_at_least_n_machines, :by_type_id, :by_operator_id, :user_faved, :by_city_name, :by_state_name, :by_city_no_state, :by_machine_type, :by_machine_display, :manufacturer

  rate_limit to: 100, within: 10.minutes, only: :region
  rate_limit to: 100, within: 5.minutes

  def map
    user = current_user.nil? ? nil : current_user

    params[:user_faved] = user.id if user && !params[:user_faved].blank?

    if !params[:by_location_id].blank? && (loc = Location.where(id: params[:by_location_id]).first)
      @title_params[:title] = "#{loc.name} - Pinball Map"
      machine_length = " - " + loc.machine_count.to_s + " " + "machine".pluralize(loc.machine_count) unless loc.machine_count.zero?
      machine_list = " - " + loc.machine_names_first_no_year.join(", ") unless loc.machine_names_first_no_year.empty?
      @title_params[:title_meta] = "#{loc.name} on Pinball Map! " + loc.full_street_address + machine_length.to_s + machine_list.to_s
    end

    @big_locations_sample = Location.select("name, random() as r").joins(:location_machine_xrefs).group("id").having("count(location_machine_xrefs)>9").order("r").first
    @location_placeholder = @big_locations_sample.nil? ? "e.g. Ground Kontrol" : "e.g. " + @big_locations_sample.name

    @machine_sample = Machine.select("name, random() as r").order("r").limit(1).first
    @machine_placeholder = @machine_sample.nil? ? "e.g. Lord of the Rings" : "e.g. " + @machine_sample.name

    @big_cities_sample = Location.select(%i[city state], "random() as r").having("count(city)>9").where.not(state: [ nil, "" ]).group("city", "state").order("r").limit(1).first
    @big_cities_placeholder = @big_cities_sample.nil? ? "e.g. Portland, OR" : "e.g. " + @big_cities_sample.city + ", " + @big_cities_sample.state

    @map_no_params = params[:address].blank? && params[:by_machine_id].blank? && params[:by_machine_single_id].blank? && params[:by_machine_group_id].blank? && params[:by_machine_name].blank? && params[:by_location_name].blank? && params[:by_location_id].blank? && params[:user_faved].blank? && params[:by_city_name].blank? && params[:by_city_id].blank? && params[:by_state_name].blank? && params[:by_city_no_state].blank? && params[:by_at_least_n_machines].blank? && params[:by_at_least_n_machines_type].blank? && params[:by_type_id].blank? && params[:by_ic_active].blank? && params[:by_machine_type].blank? && params[:by_machine_display].blank? && params[:manufacturer].blank?

    if @map_no_params
      @nearby_lat = 39.5718
      @nearby_lon = -99.1066
      if is_bot?
        @map_init_zoom = 18
      else
        @map_init_zoom = 4
      end

      if ENV["GEO_BUCKET"] && !is_bot?
        geocode_ip
        if !@nearby_lat.nil?
          @map_init_zoom = 6
        end
      end
    end
  end

  def geocode_ip
    @nearby_lat, @nearby_lon = ""

    if Rails.env.production? || Rails.env.staging?
      @nearby_lat, @nearby_lon = Geocoder.search("#{request.remote_ip}").first.coordinates
    elsif Rails.env.development?
      @nearby_lat, @nearby_lon = Geocoder.search("174.203.131.43").first.coordinates # random IP instead of localhost
    elsif Rails.env.test?
      # hardcode a PDX lat/lon during tests
      @nearby_lat = 45.5905
      @nearby_lon = -122.7549
    end
  end

  def map_nearby
    @locations = []
    @nearby_lat = nil
    if ENV["GEO_BUCKET"] && !is_bot?
      geocode_ip
    end

    if !@nearby_lat.nil?
      @near_distance = 50
      nearby_locations
    elsif @nearby_lat.nil? || @locations.size == 0
      flash.now[:alert] = "Can't find your location or you're in a desert."
    end
  end

  def find_nearby
    while @locations.blank? && @near_distance < 600
      @locations = apply_scopes(Location).near([ @nearby_lat, @nearby_lon ], @near_distance, select: "locations.id, locations.lat, locations.lon, locations.machine_count")
      if @locations.empty?
        @near_distance += 100
      end
    end
  end

  def nearby_locations
    @results_init = true
    @locations_size = 0
    @machines_sum = 0
    @locations_geojson = []

    if @nearby_lat.present?
      find_nearby
      construct_geojson
    end

    nearby_locations_load
  end

  def nearby_locations_load
    @results_init = params[:results_init] if @results_init.blank?
    boundsData = nil

    if @locations_size == 0 && @results_init == true
      @locations = []
    elsif @locations_size == 1 && @results_init == true
      @pagy, @locations = pagy(apply_scopes(Location).near([ @nearby_lat, @nearby_lon ], @near_distance).includes(:location_type))
    else
      @pagy, @locations = pagy(apply_scopes(Location.near([ @nearby_lat, @nearby_lon ], @near_distance, select: "locations.id, locations.lat, locations.lon, locations.name, locations.location_type_id, locations.street, locations.city, locations.state, locations.zip, locations.machine_count")).includes(:location_type), limit: 50, request_path: "/nearby_locations_load")
    end

    if @results_init == true
      render partial: "locations/locations", layout: false
    else
      render partial: "locations/render_locations", object: @locations
    end
  end

  def region_init_load
    @results_init = true
    @region_id = params[:region_id]
    @locations = []
    @locations_size = 0
    @machines_sum = 0

    @locations = apply_scopes(Location).where(region_id: @region_id).select([ "id", "lat", "lon", "machine_count" ])

    construct_geojson

    region_location_load
  end

  def region_location_load
    @results_init = params[:results_init] if @results_init.blank?
    boundsData = nil
    @region_id = params[:region_id]
    @region = Region.find_by_id(params[:region_id])

    if @locations_size == 0 && @results_init == true
      @locations = []
    elsif @locations_size == 1 && @results_init == true
      @pagy, @locations = pagy(apply_scopes(Location).where([ "region_id = ?", @region_id ]).includes(:location_type))
    else
      @pagy, @locations = pagy(apply_scopes(Location).where([ "region_id = ?", @region_id ]).where(city_condition).where(zone_condition).select([ "id", "lat", "lon", "name", "location_type_id", "street", "city", "state", "zip", "machine_count" ]).order("locations.name").includes(:location_type), limit: 50, request_path: "/region_location_load")
    end

    if @results_init == true
      render partial: "locations/locations", layout: false
    else
      render partial: "locations/render_locations", object: @locations
    end
  end

  def get_bounds
    @results_init = true
    @locations = []
    @locations_size = 0
    @machines_sum = 0

    @bounds = [ params[:boundsData][:sw][:lat], params[:boundsData][:sw][:lng], params[:boundsData][:ne][:lat], params[:boundsData][:ne][:lng] ]

    @locations = apply_scopes(Location).within_bounding_box(@bounds).select([ "id", "lat", "lon", "machine_count" ])

    construct_geojson

    get_bounds_load
  end

  def get_bounds_load
    @results_init = params[:results_init] if @results_init.blank?
    @bounds = [ params[:boundsData][:sw][:lat], params[:boundsData][:sw][:lng], params[:boundsData][:ne][:lat], params[:boundsData][:ne][:lng] ]

    if @locations_size == 0 && @results_init == true
      @locations = []
    elsif @locations_size == 1 && @results_init == true
      @pagy, @locations = pagy(apply_scopes(Location).within_bounding_box(@bounds).includes(:location_type))
    else
      @pagy, @locations = pagy(apply_scopes(Location).within_bounding_box(@bounds).select([ "id", "lat", "lon", "name", "location_type_id", "street", "city", "state", "zip", "machine_count" ]).order("locations.name").includes(:location_type), limit: 50, request_path: "/get_bounds_load")
    end

    if @results_init == true
      render partial: "locations/locations", layout: false
    else
      render partial: "locations/render_locations", object: @locations
    end
  end

  def construct_geojson
    @locations_size = @locations.size
    @machines_sum = @locations.sum(&:machine_count)

    @locations_geojson = @locations.sort { |a, b| a.machine_count - b.machine_count }.map.with_index do |location, index|
      {
        type: "Feature",
        id: location.id,
        properties: {
          machine_count: location.machine_count,
          id: location.id,
          order: index
        },
        geometry: {
          type: "Point",
          coordinates: [ location.lon.to_f, location.lat.to_f ]
        }
      }
    end.to_json
  end

  def map_location_data
    @locations = []
    @locations_size = 0
    @machines_sum = 0
    @results_init = true

    params.delete(:by_machine_name) unless params[:by_machine_id].blank? && params[:by_machine_single_id].blank?

    @nearby_lat, @nearby_lon = ""
    if Rails.env.test?
      # hardcode a PDX lat/lon during tests
      @nearby_lat = 45.5905
      @nearby_lon = -122.7549
    end
    if params[:address].blank? || !params[:by_city_name].blank? || !params[:by_city_no_state].blank?
      @locations = apply_scopes(Location).select([ "id", "lat", "lon", "machine_count" ]).uniq
      if @locations.blank? && !params[:by_city_name].blank?
        params.delete(:by_city_name)
        params.delete(:by_state_name)
        params.delete(:by_city_no_state)
      end
    end
    if @locations.blank?
      geocode unless params[:address].blank? || Rails.env.test?
      @near_distance = 15
      nearby_locations
    else
      construct_geojson

      map_location_load
    end
  end

  def map_location_load
    @results_init = params[:results_init] if @results_init.blank?
    boundsData = nil
    if @locations_size == 0 && @results_init == true
      @locations = []
    elsif @locations_size == 1 && @results_init == true
      @pagy, @locations = pagy(apply_scopes(Location).distinct.includes(:location_type))
    else
      @pagy, @locations = pagy(apply_scopes(Location).select([ "id", "lat", "lon", "name", "location_type_id", "street", "city", "state", "zip", "machine_count" ]).distinct.order("locations.name").includes(:location_type), limit: 50, request_path: "/map_location_load")
    end

    if @results_init == true
      render partial: "locations/locations", layout: false, object: @locations
    else
      render partial: "locations/render_locations", object: @locations
    end
  end

  def operator_location_data
    @results_init = true
    @locations_size = 0
    @machines_sum = 0
    @locations = Location.where(operator_id: params[:by_operator_id]).select([ "id", "lat", "lon", "machine_count" ])

    construct_geojson

    operator_location_load
  end

  def operator_location_load
    @results_init = params[:results_init] if @results_init.blank?
    boundsData = nil

    if @locations_size == 0 && @results_init == true
      @locations = []
    elsif @locations_size == 1 && @results_init == true
      @pagy, @locations = pagy(Location.where(operator_id: params[:by_operator_id]).includes(:location_type))
    else
      @pagy, @locations = pagy(Location.where(operator_id: params[:by_operator_id]).select([ "id", "lat", "lon", "name", "location_type_id", "street", "city", "state", "zip", "machine_count" ]).order("locations.name").includes(:location_type).limit(100))
    end

    if @results_init == true
      render partial: "locations/locations", layout: false, object: @locations
    else
      render partial: "locations/render_locations", object: @locations
    end
  end

  def geocode
    results = Geocoder.search(params[:address], lookup: :here)
    results = Geocoder.search(params[:address]) if results.blank?
    if results.present?
      @nearby_lat, @nearby_lon = results.first.coordinates
    end
  end

  def region
    @locations = Location.where("region_id = ?", @region.id).includes(:location_type, :operator)
    @location_count = @locations.count
    @lmx_count = @region.machines_count

    if !params[:by_location_id].blank? && (loc = Location.where(id: params[:by_location_id]).first)
      @title_params[:title] = "#{loc.name} - #{@region.full_name} Pinball Map"
      machine_length = " - " + loc.machine_count.to_s + " " + "machine".pluralize(loc.machine_count) unless loc.machine_count.zero?
      machine_list = " - " + loc.machine_names_first_no_year.join(", ") unless loc.machine_names_first_no_year.empty?
      @title_params[:title_meta] = "#{loc.name} on Pinball Map! " + loc.full_street_address + machine_length.to_s + machine_list.to_s
    end

    if @region
      @region_fullname = "the " + @region.full_name
    else
      @region_fullname = ""
    end

    cities = {}
    location_types = {}
    operators = {}

    @locations.each do |l|
      location_types[l.location_type_id] = l if l.location_type_id

      cities[l.city] = l

      operators[l.operator_id] = l if l.operator_id

      @region_no_params = params[:address].blank? && params[:by_machine_id].blank? && params[:by_machine_single_id].blank? && params[:by_machine_group_id].blank? && params[:by_machine_name].blank? && params[:by_location_name].blank? && params[:by_location_id].blank? && params[:user_faved].blank? && params[:by_city_name].blank? && params[:by_city_id].blank? && params[:by_state_name].blank? && params[:by_city_no_state].blank? && params[:by_at_least_n_machines].blank? && params[:by_at_least_n_machines_city].blank? && params[:by_at_least_n_machines_type].blank? && params[:by_at_least_n_machines_zone].blank? && params[:by_type_id].blank? && params[:by_ic_active].blank? && params[:by_machine_type].blank? && params[:by_machine_display].blank? && params[:manufacturer].blank?
    end

    @search_options = {
      "type" => {
        "id"   => "id",
        "name" => "name",
        "search_collection" => location_types.values.map(&:location_type).sort_by(&:name)
      },
      "location" => {
        "id"   => "id",
        "name" => "name_and_city",
        "search_collection" => @locations.sort_by(&:massaged_name),
        "autocomplete" => 1
      },
      "machine" => {
        "id"   => "id",
        "name" => "name_and_year",
        "search_collection" => @region.machines.sort_by(&:massaged_name),
        "autocomplete" => 1
      },
      "zone" => {
        "id"   => "id",
        "name" => "name",
        "search_collection" => Zone.where("region_id = ?", @region.id).order("name")
      },
      "operator" => {
        "id"   => "id",
        "name" => "name",
        "search_collection" => operators.values.map(&:operator).sort_by(&:name)
      },
      "city" => {
        "id"   => "city",
        "name" => "city",
        "search_collection" => cities.values.sort_by(&:city)
      }
    }

    render "#{@region.name}/region" if lookup_context.find_all("#{@region.name}/region").any?
  end

  private

  def city_condition
    [ "city = ?", params[:by_city_id] ] unless params[:by_city_id].blank?
  end

  def zone_condition
    [ "zone_id = ?", params[:by_zone_id] ] unless params[:by_zone_id].blank?
  end
end
