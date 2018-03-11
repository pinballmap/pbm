module Api
  module V1
    class LocationTypesController < InheritedResources::Base
      protect_from_forgery with: :null_session, if: -> { request.format.json? }

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
