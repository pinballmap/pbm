module Api
  module V1
    class LocationsController < InheritedResources::Base
      respond_to :json
      has_scope :by_location_name, :by_location_id, :by_machine_id, :by_machine_name, :by_city_id, :by_zone_id, :by_operator_id, :by_type_id, :by_at_least_n_machines_city, :by_at_least_n_machines_zone, :by_at_least_n_machines_type, :region

      def suggest
        region = Region.find(params['region_id'])

        Pony.mail(
          :to => region.users.collect {|u| u.email},
          :bcc => User.all.select {|u| u.is_super_admin }.collect {|u| u.email},
          :from => 'admin@pinballmap.com',
          :subject => "PBM - New location suggested for #{region.name} the pinball map",
          :body => <<END
Location Name: #{params['location_name']}\n
Street: #{params['location_street']}\n
City: #{params['location_city']}\n
State: #{params['location_state']}\n
Zip: #{params['location_zip']}\n
Phone: #{params['location_phone']}\n
Website: #{params['location_website']}\n
Operator: #{params['location_operator']}\n
Machines: #{params['location_machines']}\n
Their Name: #{params['submitter_name']}\n
Their Email: #{params['submitter_email']}\n
END
        )
        return_response("Thanks for entering that location. We'll get it in the system as soon as possible.",'response')
        
        rescue ActiveRecord::RecordNotFound
          return_response('Failed to find region', 'errors')
      end

      def index
        locations = apply_scopes(Location).order('locations.name')
        return_response(locations,'locations',[:location_machine_xrefs])
      end

      def update
        location = Location.find(params[:id])

        description = params[:description]
        website = params[:website]
        phone = params[:phone]
        location_type = params[:location_type]

        if (description)
          location.description = description
        end

        if (website)
          location.website = website
        end

        if (phone)
          location.phone = phone
        end

        if (location_type)
          type = LocationType.find(location_type)
          location.location_type = type
        end

        if (location.save)
          return_response(location, 'location')
        else
          return_response(location.errors.full_messages, 'errors')
        end

        rescue ActiveRecord::RecordNotFound
          return_response('Failed to find location', 'errors')
      end

    end
  end
end
