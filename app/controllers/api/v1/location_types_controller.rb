module Api
  module V1
    class LocationTypesController < BaseController
      skip_before_action :verify_authenticity_token

      before_action :allow_cors

      api :GET, "/api/v1/location_types.json", "Fetch all location types"
      formats [ "json" ]
      def index
        json = Rails.cache.fetch(LocationType::MOBILE_CACHE_KEY, expires_in: 1.week) do
          except = %i[created_at updated_at]
          { location_types: LocationType.all.as_json(except: except) }.to_json
        end
        render json: json
      end
    end
  end
end
