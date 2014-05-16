module Api
  module V1
    class LocationsController < InheritedResources::Base
      respond_to :json
      has_scope :by_location_name, :by_location_id, :by_machine_id, :by_machine_name, :by_city_id, :by_zone_id, :by_operator_id, :by_type_id, :by_at_least_n_machines_city, :by_at_least_n_machines_zone, :by_at_least_n_machines_type, :region

      def index
      	locations = apply_scopes(Location).order('locations.name')
        return_response(locations,'locations',[:location_machine_xrefs])
      end

      def update
        location = Location.find(params[:id])

        description = params[:description]
        website = params[:website]
        phone = params[:phone]

        if (description)
          location.description = description
        end

        if (website)
          location.website = website
        end

        if (phone)
          location.phone = phone
        end

        if (location.save)
          return_response(location,'location')
        else
          return_response(location.errors.full_messages,'errors')
        end
      end

    end
  end
end