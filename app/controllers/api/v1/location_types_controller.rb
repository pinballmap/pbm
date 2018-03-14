module Api
  module V1
    class LocationTypesController < InheritedResources::Base
      skip_before_action :verify_authenticity_token

      before_action :allow_cors
      respond_to :json

      api :GET, '/api/v1/location_types.json', 'Fetch all location types'
      formats ['json']
      def index
        return_response(LocationType.all, 'location_types')
      end
    end
  end
end
