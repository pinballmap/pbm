module Api
  module V1
    class LocationsController < InheritedResources::Base
      respond_to :xml,:json
      has_scope :region

      def index
        @locations = apply_scopes(Location).order("locations.name").includes(:location_machine_xrefs, :location_picture_xrefs)
        respond_with(@locations,:include=>[:location_machine_xrefs, :location_picture_xrefs])
      end
    end
  end
end