module Api
  module V1
    class LocationsController < InheritedResources::Base
      include ActionView::Helpers::NumberHelper
      before_filter :allow_cors
      respond_to :json
      has_scope :by_location_name, :by_location_id, :by_machine_id, :by_machine_name, :by_city_id, :by_zone_id, :by_operator_id, :by_type_id, :by_machine_group_id, :by_at_least_n_machines_city, :by_at_least_n_machines_zone, :by_at_least_n_machines_type, :region, :by_ipdb_id

      MAX_MILES_TO_SEARCH_FOR_CLOSEST_LOCATION = 50

      api :POST, '/api/v1/locations/suggest.json', 'Suggest a new location to add to the map'
      description "This doesn't actually create a new location, it just sends location information to region admins"
      param :region_id, Integer, desc: 'ID of the region that the location belongs in', required: true
      param :location_name, String, desc: 'Name of new location', required: true
      param :location_street, String, desc: 'Street address of new location', required: false
      param :location_city, String, desc: 'City of new location', required: false
      param :location_state, String, desc: 'State of new location', required: false
      param :location_zip, String, desc: 'Zip code of new location', required: false
      param :location_phone, String, desc: 'Phone number of new location', required: false
      param :location_website, String, desc: 'Website of new location', required: false
      param :location_operator, String, desc: 'Machine operator of new location', required: false
      param :location_machines, String, desc: 'List of machines at new location', required: true
      param :submitter_name, String, desc: 'Name of submitter', required: false
      param :submitter_email, String, desc: 'Email address of submitter', required: false
      formats ['json']
      def suggest
        if params[:region_id].blank? || params[:location_machines].blank? || params[:location_name].blank?
          return_response('Region, location name, and a list of machines are required', 'errors')
          return
        end

        region = Region.find(params['region_id'])
        send_new_location_notification(params, region)

        return_response("Thanks for entering that location. We'll get it in the system as soon as possible.", 'msg')

        rescue ActiveRecord::RecordNotFound
          return_response('Failed to find region', 'errors')
      end

      api :GET, '/api/v1/region/:region/locations.json', 'Fetch locations for a single region'
      description 'This will also return a list of machines at each location'
      param :region, String, desc: 'Name of the Region you want to see events for', required: true
      param :by_location_name, String, desc: 'Name of location to search for', required: false
      param :by_location_id, Integer, desc: 'Location ID to search for', required: false
      param :by_machine_id, Integer, desc: 'Machine ID to find in locations', required: false
      param :by_ipdb_id, Integer, desc: 'IPDB ID to find in locations', required: false
      param :by_machine_name, String, desc: 'Find machine name in locations', required: false
      param :by_city_id, String, desc: 'City to search for', required: false
      param :by_machine_group_id, String, desc: 'Machine Group to search for', required: false
      param :by_zone_id, Integer, desc: 'Zone ID to search by', required: false
      param :by_operator_id, Integer, desc: 'Operator ID to search by', required: false
      param :by_type_id, Integer, desc: 'Location type ID to search by', required: false
      param :by_at_least_n_machines_type, Integer, desc: 'Only locations with N or more machines', required: false
      formats ['json']
      def index
        locations = apply_scopes(Location).order('locations.name')
        return_response(locations, 'locations', [location_machine_xrefs: { include: :machine_conditions }])
      end

      api :PUT, '/api/v1/locations/:id.json', 'Update attributes on a location'
      param :id, Integer, desc: 'ID of location', required: true
      param :description, String, desc: 'Description of location', required: false
      param :website, String, desc: 'Website of location', required: false
      param :phone, String, desc: 'Phone number of location', required: false
      param :location_type, Integer, desc: 'ID of location type', required: false
      formats ['json']
      def update
        location = Location.find(params[:id])

        description = params[:description]
        website = params[:website]
        phone = params[:phone]
        location_type = params[:location_type]

        location_type = location_type.to_s if location_type

        location.description = description if description
        location.website = website if website
        if !location_type.blank? && !location_type.nil? && !location_type.empty?
          location.location_type = LocationType.find(location_type)
        else
          location.location_type = nil
        end

        update_phone(location, phone)

        location.save ? return_response(location, 'location') : return_response(location.errors.full_messages, 'errors')

        rescue ActiveRecord::RecordNotFound
          return_response('Failed to find location', 'errors')
      end

      def update_phone(location, phone)
        if phone && !phone.blank?
          phone.gsub!(/\s+/, '')
          phone.gsub!(/[^0-9]/, '')

          phone = phone.empty? ? 'empty' : number_to_phone(phone)
          location.phone = phone
        elsif phone && phone.blank?
          location.phone = nil
        end
      end

      api :GET, '/api/v1/locations/closest_by_lat_lon.json', 'Returns the closest location to transmitted lat/lon'
      description "This sends you the closest location to your lat/lon (defaults to within #{MAX_MILES_TO_SEARCH_FOR_CLOSEST_LOCATION} miles). It includes a list of machines at the location."
      param :lat, String, desc: 'Latitude', required: true
      param :lon, String, desc: 'Longitude', required: true
      param :max_distance, String, desc: 'Closest location within "max_distance" miles', required: false
      param :send_all_within_distance, String, desc: "Send all locations within max_distance param, or #{MAX_MILES_TO_SEARCH_FOR_CLOSEST_LOCATION} miles.", required: false
      formats ['json']
      def closest_by_lat_lon
        max_distance = params[:max_distance] ||= MAX_MILES_TO_SEARCH_FOR_CLOSEST_LOCATION

        closest_location = Location.near([params[:lat], params[:lon]], max_distance).first

        if params[:send_all_within_distance]
          closest_locations = Location.near([params[:lat], params[:lon]], max_distance)
          return_response(closest_locations, 'locations', [], [:machine_names])
        elsif closest_location
          return_response(closest_location, 'location', [], [:machine_names])
        else
          return_response("No locations within #{max_distance} miles.", 'errors')
        end
      end

      api :GET, '/api/v1/locations/:id/machine_details.json', 'Display the details of the machines at this location'
      param :id, Integer, desc: 'ID of location', required: true
      formats ['json']
      def machine_details
        location = Location.find(params[:id])

        machines = []
        location.machines.sort { |x, y| x.name <=> y.name }.each do |m|
          machines.push(
            id: m.id,
            name: m.name,
            year: m.year,
            manufacturer: m.manufacturer,
            ipdb_link: m.ipdb_link,
            ipdb_id: m.ipdb_id
          )
        end

        return_response(machines, 'machines')

        rescue ActiveRecord::RecordNotFound
          return_response('Failed to find location', 'errors')
      end
    end
  end
end
