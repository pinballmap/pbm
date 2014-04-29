module Api
  module V1
    class LocationsController < InheritedResources::Base
      respond_to :xml, :json
      has_scope :by_location_name, :by_location_id, :by_machine_id, :by_machine_name, :by_city_id, :by_zone_id, :by_operator_id, :by_type_id, :by_at_least_n_machines_city, :by_at_least_n_machines_zone, :by_at_least_n_machines_type, :region

      def index
        respond_with apply_scopes(Location).order('locations.name')
      end

    end
  end
end
