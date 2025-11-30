module Api
  module V1
    class LocationsController < ApplicationController
      include ActionView::Helpers::NumberHelper
      include Pagy::Backend
      skip_before_action :verify_authenticity_token

      before_action :allow_cors
      has_scope :by_location_name, :by_location_id, :by_machine_id, :by_machine_name, :by_city_id, :by_state_id, :by_country, :by_zone_id, :by_operator_id, :by_type_id, :by_machine_single_id, :by_machine_group_id, :by_at_least_n_machines, :by_at_least_n_machines_city, :by_at_least_n_machines_zone, :by_at_least_n_machines_type, :region, :by_ipdb_id, :by_opdb_id, :by_is_stern_army, :regionless_only, :manufacturer, :by_ic_active, :by_machine_type, :by_machine_display, :by_machine_id_ic, :by_machine_single_id_ic, :by_machine_year
      rate_limit to: 30, within: 10.minutes, only: [ :suggest, :update ]

      MAX_MILES_TO_SEARCH_FOR_CLOSEST_LOCATION = 50

      api :POST, "/api/v1/locations/suggest.json", "Suggest a new location to add to the map"
      description "This doesn't actually create a new location, it just sends location information to region admins. Please send a region or lat/lon combo to get suggestions to the right people."
      param :location_name, String, desc: "Name of new location", required: true
      param :region_id, Integer, desc: "ID of the region that the location belongs in", required: false
      param :lat, String, desc: "Latitude", required: false
      param :lon, String, desc: "Longitude", required: false
      param :location_street, String, desc: "Street address of new location", required: false
      param :location_city, String, desc: "City of new location", required: false
      param :location_state, String, desc: "State of new location", required: false
      param :location_zip, String, desc: "Zip code of new location", required: false
      param :location_phone, String, desc: "Phone number of new location", required: false
      param :location_website, String, desc: "Website of new location", required: false
      param :location_type, String, desc: "Type of location", required: false
      param :location_operator, String, desc: "Machine operator of new location", required: false
      param :location_zone, String, desc: "Machine operator of new location", required: false
      param :location_comments, String, desc: "Comments", required: false
      param :location_machines, String, desc: "List of machines at new location", required: false
      param :location_machines_ids, String, desc: "List of machine ids at new location", required: false
      formats [ "json" ]
      def suggest
        user = current_user.nil? ? nil : current_user

        return return_response(AUTH_REQUIRED_MSG, "errors") if user.nil?

        if params[:location_machines].blank? || params[:location_name].blank?
          return_response("Location name, and a list of machines are required", "errors")
          return
        end

        region = nil
        region = Region.find(params["region_id"]) unless params[:region_id].blank?

        send_new_location_notification(params, region, user)

        return_response("Thanks for your submission! We'll review and add it soon. Be patient!", "msg")
      rescue ActiveRecord::RecordNotFound
        return_response("Failed to find region", "errors")
      end

      api :GET, "/api/v1/locations.json", "Fetch locations for all regions"
      api :GET, "/api/v1/region/:region/locations.json", "Fetch locations for a single region"
      description "This will also return a list of machines at each location"
      param :region, String, desc: "Name of the Region you want to see locations for", required: true
      param :by_location_name, String, desc: "Name of location to search for", required: false
      param :by_location_id, Integer, desc: "Location ID to search for", required: false
      param :by_machine_id, Integer, desc: "Machine ID to find in locations. Returns locations with all variant models of the machine", required: false
      param :by_machine_single_id, Integer, desc: "Machine ID to find in locations, returns only exact version", required: false
      param :by_machine_group_id, String, desc: "Machine Group to search for", required: false
      param :by_machine_id_ic, Integer, desc: "Machine ID to find in locations, when Stern Insider Connected is enabled for that machine at that location. Returns locations with all variant models of the machine. ", required: false
      param :by_machine_single_id_ic, Integer, desc: "Machine ID to find in locations, when Stern Insider Connected is enabled for that machine at that location. Returns locations with exact model of the machine.", required: false
      param :manufacturer, String, desc: "Locations with machines from this manufacturer. Additional filtering required for this endpoint.", required: false
      param :by_machine_year, Integer, desc: "Locations with at least one machine manufacturered in this year. Additional filtering required for this endpoint.", required: false
      param :by_ipdb_id, Integer, desc: "IPDB ID to find in locations", required: false
      param :by_opdb_id, Integer, desc: "OPDB ID to find in locations", required: false
      param :by_machine_name, String, desc: "Find machine name in locations", required: false
      param :by_city_id, String, desc: "City to search for", required: false
      param :by_state_id, String, desc: "State to search for. Matches location state field (often an abbreviation). Additional filtering required for this endpoint.", required: false
      param :by_country, String, desc: "Country to search for. Matches location country code, in all caps, such as 'US'. Additional filtering required for this endpoint.", required: false
      param :by_zone_id, Integer, desc: "Zone ID to search by", required: false
      param :by_operator_id, Integer, desc: "Operator ID to search by", required: false
      param :by_type_id, Integer, desc: "Location type ID to search by", required: false
      param :by_at_least_n_machines, Integer, desc: "Only locations with N or more machines. Additional filtering required for this endpoint.", required: false
      param :by_at_least_n_machines_type, Integer, desc: "Only locations with N or more machines. Additional filtering required for this endpoint.", required: false
      param :by_is_stern_army, Integer, desc: "Send only locations labeled as Stern Army", required: false
      param :by_ic_active, :boolean, desc: "Send only locations that have at least one machine that is tagged as Stern Insider Connected. Additional filtering required for this endpoint.", required: false
      param :by_machine_type, String, desc: "Locations with machines of this type (em, ss, me). Additional filtering required for this endpoint.", required: false
      param :by_machine_display, String, desc: "Locations with machines with this display (alphanumeric, lcd, dmd, reels, lights). Additional filtering required for this endpoint.", required: false
      param :no_details, Integer, desc: "Omit lmx/condition data from pull. Additional filtering required for this endpoint.", required: false
      param :with_lmx, Integer, desc: "Include location machine details such as comments. Additional filtering required for this endpoint.", required: false
      param :regionless_only, Integer, desc: "Show only regionless locations", required: false
      formats [ "json" ]
      def index
        return return_response(FILTERING_REQUIRED_MSG, "errors") unless %i[region by_location_name by_location_id by_machine_id by_machine_single_id by_machine_group_id by_machine_id_ic by_machine_single_id_ic by_ipdb_id by_opdb_id by_machine_name by_city_id by_zone_id by_operator_id by_type_id by_is_stern_army regionless_only].any? { params[_1].present? }

        except = params[:no_details] ? %i[phone website description created_at updated_at date_last_updated last_updated_by_user_id region_id users_count user_submissions_count] : nil

        locations = nil
        if params[:no_details] || params[:by_is_stern_army]
          locations = apply_scopes(Location).includes(:machines, :last_updated_by_user).order("locations.name").uniq
        elsif params[:with_lmx] && !params[:regionless_only]
          locations = apply_scopes(Location).includes({ location_machine_xrefs: %i[user machine_conditions] }, :machines, :last_updated_by_user).order("locations.name").uniq
        else
          locations = apply_scopes(Location).includes(:machines, :last_updated_by_user).order("locations.name").uniq
        end

        if params[:by_is_stern_army]
          return_response(
            locations,
            "locations",
            [],
            %i[machine_names last_updated_by_username num_machines],
            200,
            except
          )
        elsif params[:with_lmx] && !params[:regionless_only]
          return_response(
            locations,
            "locations",
            params[:no_details] ? nil : [ location_machine_xrefs: { include: { machine_conditions: { methods: :username }, machine: { methods: :machine_group_id } }, methods: :last_updated_by_username } ],
            %i[last_updated_by_username num_machines],
            200,
            except
          )
        else
          return_response(
            locations,
            "locations",
            params[:no_details] ? nil : [ location_machine_xrefs: { include: { machine: { except: %i[created_at opdb_img opdb_img_height opdb_img_width ic_eligible is_active machine_type machine_display] } }, except: %i[user_id] } ],
            %i[last_updated_by_username num_machines],
            200,
            except
          )
        end
      end

      api :PUT, "/api/v1/locations/:id.json", "Update attributes on a location"
      param :id, Integer, desc: "ID of location", required: true
      param :description, String, desc: "Description of location", required: false
      param :website, String, desc: "Website of location", required: false
      param :phone, String, desc: "Phone number of location", required: false
      param :location_type, Integer, desc: "ID of location type", required: false
      param :operator_id, Integer, desc: "ID of the operator", required: false
      formats [ "json" ]
      def update
        location = Location.find(params[:id])
        user = current_user.nil? ? nil : current_user

        return return_response(AUTH_REQUIRED_MSG, "errors") if user.nil?

        values, message_type = location.update_metadata(
          user,
          description: params[:description],
          website: params[:website],
          phone: params[:phone],
          location_type_id: params[:location_type],
          operator_id: params[:operator_id]
        )

        return_response(values, message_type)
      rescue ActiveRecord::RecordNotFound
        return_response("Failed to find location", "errors")
      end

      api :GET, "/api/v1/locations/closest_by_lat_lon.json", "Returns the closest location to transmitted lat/lon"
      description "This sends you the closest location to your lat/lon (defaults to within #{MAX_MILES_TO_SEARCH_FOR_CLOSEST_LOCATION} miles). It includes a list of machines at the location."
      param :lat, String, desc: "Latitude", required: true
      param :lon, String, desc: "Longitude", required: true
      param :by_type_id, Integer, desc: "Location type ID to search by", required: false
      param :manufacturer, String, desc: "Locations with machines from this manufacturer", required: false
      param :by_machine_id, Integer, desc: "Machine ID to find in locations", required: false
      param :by_machine_single_id, Integer, desc: "Machine ID to find in locations, returns only exact version", required: false
      param :by_machine_group_id, String, desc: "Machine Group to search for", required: false
      param :by_machine_id_ic, Integer, desc: "Machine ID to find in locations, when Stern Insider Connected is enabled for that machine at that location. Returns locations with all variant models of the machine", required: false
      param :by_machine_single_id_ic, Integer, desc: "Machine ID to find in locations, when Stern Insider Connected is enabled for that machine at that location. Returns locations with exact model of the machine", required: false
      param :by_machine_year, Integer, desc: "Locations with at least one machine manufacturered in this year", required: false
      param :by_operator_id, Integer, desc: "Operator ID to search by", required: false
      param :by_at_least_n_machines, Integer, desc: "Only locations with N or more machines", required: false
      param :by_at_least_n_machines_type, Integer, desc: "Only locations with N or more machines", required: false
      param :by_machine_type, String, desc: "Locations with machines of this type (em, ss, me)", required: false
      param :by_machine_display, String, desc: "Locations with machines with this display (alphanumeric, lcd, dmd, reels, lights)", required: false
      param :max_distance, String, desc: 'Closest location within "max_distance" miles, with a max of 500', required: false
      param :no_details, Integer, desc: "Omit data that app does not need from pull", required: false
      param :send_all_within_distance, String, desc: "Send all locations within max_distance param, or #{MAX_MILES_TO_SEARCH_FOR_CLOSEST_LOCATION} miles.", required: false
      formats [ "json" ]
      def closest_by_lat_lon
        if params[:max_distance].blank?
          max_distance = MAX_MILES_TO_SEARCH_FOR_CLOSEST_LOCATION
        elsif !params[:no_details] && params[:max_distance].to_i > 500
          max_distance = 500
        elsif params[:no_details] && params[:max_distance].to_i > 800
          max_distance = 800
        else
          max_distance = params[:max_distance].to_i
        end

        except = params[:no_details] ? %i[country last_updated_by_user_id description region_id zone_id website phone users_count user_submissions_count] : nil

        closest_locations = apply_scopes(Location).includes(:machines).near([ params[:lat], params[:lon] ], max_distance).uniq

        if !closest_locations.empty? && !params[:send_all_within_distance]
          return_response(closest_locations.first, "location", [], %i[machine_names machine_ids num_machines], 200, except)
        elsif !closest_locations.empty?
          return_response(closest_locations, "locations", [], %i[machine_names machine_ids num_machines], 200, except)
        else
          return_response("No locations within #{max_distance} miles.", "errors")
        end
      end

      api :GET, "/api/v1/locations/within_bounding_box(.:format)", "Returns locations within transmitted bounding box"
      description "This sends locations within the sw_corner and ne_corner bounding box. It includes a list of machines at the location."
      param :swlat, String, "SW_Latitude", required: true
      param :swlon, String, "SW_Longitude", required: true
      param :nelat, String, "NE_Latitude", required: true
      param :nelon, String, "NE_Longitude", required: true
      param :by_type_id, Integer, desc: "Location type ID to search by", required: false
      param :manufacturer, String, desc: "Locations with machines from this manufacturer. Multiple names can be chained together with underscores.", required: false
      param :by_machine_id, Integer, desc: "Machine ID to find in locations, returns all versions in group. Multiple IDs can be chained together with underscores.", required: false
      param :by_machine_single_id, Integer, desc: "Machine ID to find in locations, returns only exact version. Multiple IDs can be chained together with underscores.", required: false
      param :by_machine_group_id, String, desc: "Machine Group ID to find in locations. Multiple IDs can be chained together with underscores.", required: false
      param :by_machine_id_ic, Integer, desc: "Machine ID to find in locations, when Stern Insider Connected is enabled for that machine at that location. Returns locations with any variant models of the machine. Multiple IDs can be chained together with underscores.", required: false
      param :by_machine_single_id_ic, Integer, desc: "Machine ID to find in locations, when Stern Insider Connected is enabled for that machine at that location. Returns locations with exact model of the machine. Multiple IDs can be chained together with underscores.", required: false
      param :by_machine_year, Integer, desc: "Locations with at least one machine manufacturered in this year. Multiple years can be chained together with underscores.", required: false
      param :by_operator_id, Integer, desc: "Operator ID to search by", required: false
      param :by_ic_active, :boolean, desc: "Send only locations that have at least one machine that is tagged as Stern Insider Connected", required: false
      param :user_faved, Integer, desc: "User ID of Faved Locations", required: false
      param :by_ipdb_id, Integer, desc: "IPDB ID to find in locations. Multiple IDs can be chained together with underscores.", required: false
      param :by_opdb_id, Integer, desc: "OPDB ID to find in locations. Multiple IDs can be chained together with underscores.", required: false
      param :by_at_least_n_machines, Integer, desc: "Only locations with N or more machines", required: false
      param :by_at_least_n_machines_type, Integer, desc: "Only locations with N or more machines", required: false
      param :by_machine_type, String, desc: "Locations with machines of this type (em, ss, me). Multiple types can be chained together with underscores.", required: false
      param :by_machine_display, String, desc: "Locations with machines with this display (alphanumeric, lcd, dmd, reels, lights). Multiple display types can be chained together with underscores.", required: false
      param :no_details, Integer, desc: "Omit data that app does not need from pull (options include '1' or '2')", required: false
      param :limit, Integer, desc: "Limit results to a quantity and include pagination metadata in response", required: false
      param :order_by, String, desc: "Order results descending by a field in the locations scope. Allowed fields are updated_at, name, machine_count. Otherwise, sorts by location ID"
      formats %w[json geojson]
      def within_bounding_box
        if params[:order_by].present? and [ "updated_at", "machine_count" ].include? params[:order_by].downcase
          order_by = "locations.#{params[:order_by]} desc"
        elsif params[:order_by].present? and [ "name" ].include? params[:order_by].downcase
          order_by = "locations.#{params[:order_by]} asc"
        else
          order_by = "locations.id desc"
        end

        if params[:no_details] == "1"
          except = %i[country last_updated_by_user_id description region_id zone_id website phone ic_active is_stern_army date_last_updated created_at users_count user_submissions_count]
          includes = %i[machine_names_first machine_ids num_machines]
        elsif params[:no_details] == "2"
          except = %i[street city state zip country updated_at location_type_id operator_id country last_updated_by_user_id description region_id zone_id website phone ic_active is_stern_army date_last_updated created_at users_count user_submissions_count]
          includes = []
        else
          except = []
          includes = %i[machine_names_first machine_ids num_machines]
        end

        bounds = [ params[:swlat], params[:swlon], params[:nelat], params[:nelon] ]
        if params[:user_faved]
          user = User.find(params[:user_faved])
          fave_locations = UserFaveLocation.select(:location_id).where(user_id: user)

          if params[:limit].blank?
            locations_within = apply_scopes(Location.where(id: fave_locations)).includes(:machines).within_bounding_box(bounds).order(order_by).uniq
          else
            @pagy, locations_within = pagy(apply_scopes(Location.where(id: fave_locations)).includes(:machines).within_bounding_box(bounds).order(order_by).distinct, limit_extra: true)
          end
        elsif params[:no_details] == "2"
          locations_within = apply_scopes(Location).within_bounding_box(bounds).order(order_by).uniq
        else
          if params[:limit].blank?
            locations_within = apply_scopes(Location).includes(:machines).within_bounding_box(bounds).order(order_by).uniq
          else
            @pagy, locations_within = pagy(apply_scopes(Location).includes(:machines).within_bounding_box(bounds).order(order_by).distinct, limit_extra: true)
            @pagy_metadata = pagy_metadata(@pagy)
          end
        end

        if params[:format] == "geojson"
          locations_geojson = locations_within.map do |location|
            {
              type: "Feature",
              id: location.id,
              geometry: {
                type: "Point",
                coordinates: [ location.lon.to_f, location.lat.to_f ]
              },
              properties: {
                name: location.name,
                street: location.street,
                city: location.city,
                state: location.state,
                zip: location.zip,
                updated_at: location.updated_at,
                location_type_id: location.location_type_id,
                operator_id: location.operator_id,
                machine_ids: location.machine_ids,
                machine_names_first: location.machine_names_first,
                num_machines: location.num_machines
              }
            }
          end

          container_geojson = {
            type: "FeatureCollection",
            features: locations_geojson
          }
        end

        if !locations_within.empty?
          respond_to do |format|
            if params[:limit].blank?
              format.json { return_response(locations_within, "locations", [], includes, 200, except, nil) }
            else
              format.json { return_response(locations_within, "locations", [], includes, 200, except, true) }
            end
            format.geojson { render json: container_geojson.to_json }
          end
        else
          return_response("No locations found within bounding box.", "errors")
        end
      end

      api :GET, "/api/v1/locations/closest_by_address.json", "Returns the closest location to transmitted address"
      description "This sends you the closest location to your address (defaults to within #{MAX_MILES_TO_SEARCH_FOR_CLOSEST_LOCATION} miles). It includes a list of machines at the location."
      param :address, String, desc: "Address", required: true
      param :max_distance, String, desc: 'Closest location within "max_distance" miles, max 500', required: false
      param :send_all_within_distance, String, desc: "Send all locations within max_distance param, or #{MAX_MILES_TO_SEARCH_FOR_CLOSEST_LOCATION} miles.", required: false
      param :no_details, Integer, desc: "Omit data that app does not need from pull", required: false
      param :by_ic_active, :boolean, desc: "Send only locations that have at least one machine that is tagged as Stern Insider Connected", required: false
      param :manufacturer, String, desc: "Locations with machines from this manufacturer", required: false
      param :by_machine_type, String, desc: "Locations with machines of this type (em, ss, me)", required: false
      param :by_machine_display, String, desc: "Locations with machines with this display (alphanumeric, lcd, dmd, reels, lights)", required: false
      param :by_machine_id, Integer, desc: "Machine ID to find in locations, returns all versions in group", required: false
      param :by_machine_single_id, Integer, desc: "Machine ID to find in locations, returns only exact version", required: false
      param :by_machine_group_id, String, desc: "Machine Group to search for", required: false
      param :by_machine_id_ic, Integer, desc: "Machine ID to find in locations, when Stern Insider Connected is enabled for that machine at that location. Returns locations with all variant models of the machine", required: false
      param :by_machine_single_id_ic, Integer, desc: "Machine ID to find in locations, when Stern Insider Connected is enabled for that machine at that location. Returns locations with exact model of the machine", required: false
      param :by_machine_year, Integer, desc: "Locations with at least one machine manufacturered in this year", required: false
      formats [ "json" ]
      def closest_by_address
        if params[:max_distance].blank?
          max_distance = MAX_MILES_TO_SEARCH_FOR_CLOSEST_LOCATION
        elsif !params[:no_details] && params[:max_distance].to_i > 500
          max_distance = 500
        elsif params[:no_details] && params[:max_distance].to_i > 800
          max_distance = 800
        else
          max_distance = params[:max_distance].to_i
        end

        except = params[:no_details] ? %i[country last_updated_by_user_id description region_id zone_id website phone users_count user_submissions_count] : nil

        lat, lon = ""
        unless params[:address].blank?
          if Rails.env.test?
            # hardcode a PDX lat/lon during tests
            lat = 45.590502800000
            lon = -122.754940100000
          else
            results = Geocoder.search(params[:address], lookup: :here)
            results = Geocoder.search(params[:address]) if results.blank?
            lat, lon = results.first.coordinates
          end
        end

        closest_location = apply_scopes(Location).includes(:machines).near([ lat, lon ], max_distance).first
        location_details = [ location_machine_xrefs: { include: { machine: { methods: :machine_group_id, except: params[:no_details] ? %i[is_active created_at updated_at ipdb_link] : nil } }, except: params[:no_details] ? %i[created_at updated_at user_id] : nil } ]

        if params[:send_all_within_distance]
          closest_locations = apply_scopes(Location).includes(:machines).near([ lat, lon ], max_distance)
          return_response(closest_locations, "locations", location_details, %i[machine_names machine_ids num_machines], 200, except)
        elsif closest_location
          return_response(closest_location, "location", location_details, %i[machine_names machine_ids num_machines], 200, except)
        else
          return_response("No locations within #{max_distance} miles.", "errors")
        end
      end

      api :GET, "/api/v1/locations/:id.json", "Display the details of this location"
      param :id, Integer, desc: "ID of location", required: true
      param :no_details, Integer, desc: "Omit lmx/condition data from pull", required: false
      formats [ "json" ]
      def show
        location = nil

        if params[:no_details] == "1"
          location = Location.includes(:location_machine_xrefs, :last_updated_by_user).find(params[:id])
          return_response(
            location,
            nil,
            :location_machine_xrefs,
            %i[last_updated_by_username num_machines],
            200,
            %i[zone_id created_at region_id is_stern_army country]
          )
        elsif params[:no_details] == "2"
          location = Location.find(params[:id])
          return_response(
            location,
            nil,
            [],
            %i[machine_names_first_no_year num_machines],
            200,
            %i[phone website updated_at region_id description operator_id date_last_updated last_updated_by_user_id ic_active zone_id created_at is_stern_army country users_count user_submissions_count]
          )
        else
          location = Location.includes(location_machine_xrefs: [ :user, { machine_conditions: :user }, { machine_score_xrefs: :user } ]).find(params[:id])
          return_response(
            location,
            nil,
            [ location_machine_xrefs: { include: { machine_conditions: { methods: :username }, machine_score_xrefs: { methods: :username } }, methods: :last_updated_by_username } ],
            %i[last_updated_by_username num_machines]
          )
        end
      rescue ActiveRecord::RecordNotFound
        return_response("Failed to find location", "errors")
      end

      api :GET, "/api/v1/locations/:id/picture_details.json", "Get info about all pictures at a location"
      param :id, Integer, desc: "Location id", required: true
      formats [ "json" ]
      def picture_details
        location = Location.find(params[:id])

        pictures = []

        location.location_picture_xrefs.includes([ :photo_attachment ]).each do |lpx|
          next if lpx.photo.id.nil?
          if Rails.env.test?
            pictures.push(
              id: lpx.photo.id,
              url: rails_representation_url(lpx.photo)
            )
          else
            pictures.push(
              id: lpx.photo.id,
              url: rails_representation_url(lpx.photo.variant(resize_to_limit: [ 800, 800 ]).processed)
            )
          end
        end
        return_response(pictures, "pictures")
      rescue ActiveRecord::RecordNotFound
        return_response("Failed to find location", "errors")
      end

      api :GET, "/api/v1/locations/:id/machine_details.json", "Display the details of the machines at this location"
      param :id, Integer, desc: "ID of location", required: true
      param :machines_only, Integer, desc: "Simple list of only machine names", required: false
      formats [ "json" ]
      def machine_details
        location = Location.find(params[:id])

        machines = []
        if params[:machines_only]
          machines = location.machine_names
        else
          location.machines.sort_by(&:name).each do |m|
            machines.push(
              id: m.id,
              name: m.name,
              year: m.year,
              manufacturer: m.manufacturer,
              ipdb_link: m.ipdb_link,
              ipdb_id: m.ipdb_id,
              opdb_id: m.opdb_id
            )
          end
        end

        return_response(machines, "machines")
      rescue ActiveRecord::RecordNotFound
        return_response("Failed to find location", "errors")
      end

      api :PUT, "/api/v1/locations/:id/confirm.json", "Confirm location information"
      formats [ "json" ]
      def confirm
        user = current_user.nil? ? nil : current_user

        return return_response(AUTH_REQUIRED_MSG, "errors") if user.nil?

        location = Location.find(params[:id])
        location.confirm(user)

        return_response("Thanks for confirming the line-up at this location!", "msg")
      rescue ActiveRecord::RecordNotFound
        return_response("Failed to find location", "errors")
      end

      api :GET, "/api/v1/locations/autocomplete_city.json", "Send back a list of cities in the DB that fit your search criteria"
      param :name, String, desc: "city/state name part", required: true
      formats [ "json" ]
      def autocomplete_city
        if params.fetch(:name, "").length > 2
          locations = Location.where("clean_items(city) ilike '%' || clean_items(?) || '%'", params[:name]).sort_by(&:city).map { |l| { label: "#{l.city}#{l.state.blank? ? '' : ', '}#{l.state}", value: "#{l.city}#{l.state.blank? ? '' : ', '}#{l.state}" } }
        else
          locations = []
        end

        return_response(
          locations.uniq,
          nil,
          []
        )
      end

      api :GET, "/api/v1/locations/autocomplete.json", "Send back fuzzy search results of search params"
      param :name, String, desc: "name to fuzzy search with", required: true
      formats [ "json" ]
      def autocomplete
        if params.fetch(:name, "").length > 2
          locations = Location.where("clean_items(name) ilike '%' || clean_items(?) || '%'", params[:name]).sort_by(&:name).map { |l| { label: "#{l.name} (#{l.city}#{l.state.blank? ? '' : ', '}#{l.state})", value: l.name, id: l.id } }
        else
          locations = []
        end

        return_response(
          locations,
          nil,
          []
        )
      end

      api :GET, "/api/v1/locations/top_cities.json", "Fetch top 10 cities by number of locations"
      description "Fetch top 10 cities by number of locations"
      formats [ "json" ]
      def top_cities
        top_cities = Location.select(
          [
            :city, :state, Arel.star.count.as("location_count")
          ]
        ).order(:location_count).reverse_order.group(:city, :state).limit(10)

        return_response(top_cities, nil)
      end

      api :GET, "/api/v1/locations/top_cities_by_machine.json", "Fetch top 10 cities by number of machines"
      description "Fetch top 10 cities by number of machines"
      formats [ "json" ]
      def top_cities_by_machine
        xid = Arel::Table.new("location_machine_xrefs")
        lid = Arel::Table.new("locations")
        top_cities_by_machine = Location.select(
          [
            :city, :state, Arel.star.count.as("machines_count")
          ]
        ).joins(
          Location.arel_table.join(LocationMachineXref.arel_table).on(xid[:location_id].eq(lid[:id])).join_sources
        ).order(:machines_count).reverse_order.group(:city, :state).limit(10)

        return_response(top_cities_by_machine, nil)
      end

      api :GET, "/api/v1/locations/type_count.json", "Fetch a count of each location type"
      description "Fetch a count of each location type"
      formats [ "json" ]
      def type_count
        l = Arel::Table.new("locations")
        t = Arel::Table.new("location_types")
        type_count = Location.select(
          [
            t[:name], Arel.star.count.as("type_count")
          ]
        ).joins(
          Location.arel_table.join(LocationType.arel_table).on(
            l[:location_type_id].eq(t[:id])
          ).join_sources
        ).order(:type_count).reverse_order.group(t[:name])

        return_response(type_count, nil)
      end

      api :GET, "/api/v1/locations/countries.json", "Fetch countries by number of locations"
      description "Fetch countries by number of locations"
      formats [ "json" ]
      def countries
        countries = Location.select(
          [
            :country, Arel.star.count.as("location_count")
          ]
        ).order(:location_count).reverse_order.group(:country)

        return_response(countries, nil)
      end
    end
  end
end
