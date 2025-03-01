class MapsController < InheritedResources::Base
  respond_to :xml, :json, :html, :js, :rss, only: %i[index show]
  has_scope :by_location_name, :by_location_id, :by_machine_name, :by_machine_id, :by_machine_single_id, :by_at_least_n_machines, :by_type_id, :by_operator_id, :user_faved, :by_city_name, :by_state_name

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
  end

  def nearby_locations
    coords = [ params[:position_lat], params[:position_lon] ]

    @locations = []

    @locations = apply_scopes(Location.near(coords, 50)).select(["id","lat","lon","name", "location_type_id", "street", "city", "state",  "zip", "machine_count"]).order("locations.name").includes(:location_type, :location_machine_xrefs, :machines)

    construct_geojson

    if @locations.size == 0
      @locations = []
    elsif @locations.size == 1
      @locations = apply_scopes(Location.near(coords, 50)).includes(:location_type, :location_machine_xrefs, :machines)
    else
      @locations = apply_scopes(Location.near(coords, 50)).select(["id","lat","lon","name", "location_type_id", "street", "city", "state",  "zip", "machine_count"]).order("locations.name").includes(:location_type).limit(100)
    end

    render partial: "locations/locations", layout: false
  end

  def region_init_load
    region_id = params[:region_id]
    @locations = []

    @locations = apply_scopes(Location).where(region_id: region_id).select(["id","lat","lon","machine_count"])

    construct_geojson

    if @locations.size == 0
      @locations = []
    elsif @locations.size == 1
      @locations = apply_scopes(Location).where([ "region_id = ?", region_id ]).includes(:location_type, :location_machine_xrefs, :machines)
    else
      @locations = apply_scopes(Location).where([ "region_id = ?", region_id ]).select(["id","lat","lon","name", "location_type_id", "street", "city", "state",  "zip", "machine_count"]).order("locations.name").includes(:location_type).limit(100)
    end

    @region = Region.find_by_id(region_id)

    render partial: "locations/locations", layout: false
  end

  def get_bounds
    @locations = []

    @bounds = [ params[:boundsData][:sw][:lat], params[:boundsData][:sw][:lng], params[:boundsData][:ne][:lat], params[:boundsData][:ne][:lng] ]

    @locations = apply_scopes(Location).within_bounding_box(@bounds).select(["id","lat","lon","machine_count"])

    construct_geojson

    if @locations.size == 0
      @locations = []
    elsif @locations.size == 1
      @locations = apply_scopes(Location).within_bounding_box(@bounds).includes(:location_type, :location_machine_xrefs, :machines)
    else
      @locations = apply_scopes(Location).within_bounding_box(@bounds).select(["id","lat","lon","name", "location_type_id", "street", "city", "state",  "zip", "machine_count"]).order("locations.name").includes(:location_type).limit(100)
    end

    respond_with(@locations) do |format|
      format.html { render partial: "locations/locations", layout: false }
    end
  end

  def construct_geojson
    @locations_size = @locations.size
    @machines_sum = @locations.sum(&:machine_count)

    @locations_geojson = @locations.sort {|a,b| a.machine_count - b.machine_count}.map.with_index do |location, index|
      {
        type: "Feature",
        id: location.id,
        properties: {
          machine_count: location.machine_count,
          id: location.id,
          order: index,
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
    @nearby_found = false

    params.delete(:by_machine_name) unless params[:by_machine_id].blank? && params[:by_machine_single_id].blank?

    @lat, @lon = ""
    if Rails.env.test?
      # hardcode a PDX lat/lon during tests
      @lat = 45.590502800000
      @lon = -122.754940100000
    end
    if params[:address].blank? || !params[:by_city_name].blank?
      @locations = apply_scopes(Location).select(["id","lat","lon","machine_count"])
      if @locations.blank? && !params[:by_city_name].blank?
        params.delete(:by_city_name)
        params.delete(:by_state_name)
      end
    end
    if @locations.blank?
      geocode unless params[:address].blank? || Rails.env.test?
      find_nearby
    end

    construct_geojson

    if @locations.size == 0
      @locations = []
    elsif @locations.size == 1
      @locations = apply_scopes(Location).includes(:location_type, :location_machine_xrefs, :machines)
    else
      @locations = apply_scopes(Location).select(["id","lat","lon","name", "location_type_id", "street", "city", "state",  "zip", "machine_count"]).order("locations.name").includes(:location_type).limit(100)
    end

    render partial: "locations/locations", layout: false
  end

  def operator_location_data
    @locations = Location.where(operator_id: params[:by_operator_id]).select(["id","lat","lon","machine_count"])

    construct_geojson

    if @locations.size == 0
      @locations = []
    elsif @locations.size == 1
      @locations = Location.where(operator_id: params[:by_operator_id]).includes(:location_type, :location_machine_xrefs, :machines)
    else
      @locations = Location.where(operator_id: params[:by_operator_id]).select(["id","lat","lon","name", "location_type_id", "street", "city", "state",  "zip", "machine_count"]).order("locations.name").includes(:location_type).limit(100)
    end

    render partial: "locations/locations", layout: false
  end

  def geocode
    results = Geocoder.search(params[:address], lookup: :here)
    results = Geocoder.search(params[:address]) if results.blank?
    results = Geocoder.search(params[:address], lookup: :nominatim) if results.blank?
    @lat, @lon = results.first.coordinates
  end

  def find_nearby
    @near_distance = 15
    while @locations.blank? && @near_distance < 600
      @locations = apply_scopes(Location.near([ @lat, @lon ], @near_distance)).select(["id","lat","lon","machine_count"])
      @near_distance += 100
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
end
