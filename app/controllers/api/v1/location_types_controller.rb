module Api
  module V1
    class LocationTypesController < InheritedResources::Base
      skip_before_action :verify_authenticity_token

      before_action :allow_cors
      respond_to :json

      api :GET, '/api/v1/location_types.json', 'Fetch all location types'
      formats ['json']
      def index
        location_types = LocationType.all
        except = %i[created_at updated_at]
        return_response(location_types, 'location_types', [], [], 200, except)
      end
    end
  end
end
