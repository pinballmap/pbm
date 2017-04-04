module Api
  module V1
    class LocationTypesController < InheritedResources::Base
      before_filter :allow_cors
      respond_to :json

      api :GET, '/api/v1/location_types.json', 'Fetch all location types'
      formats ['json']
      def index
        return_response(LocationType.all, 'location_types')
      end
    end
  end
end
