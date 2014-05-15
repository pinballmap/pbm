module Api
  module V1
    class LocationTypesController < InheritedResources::Base

      respond_to :xml, :json

      def index
        return_response(LocationType.all,'location_types')
      end

    end
  end
end
