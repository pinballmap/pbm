module Api
  module V1
    class ZonesController < InheritedResources::Base
      protect_from_forgery with: :null_session, if: -> { request.format.json? }

      before_action :allow_cors
      respond_to :json
      has_scope :region

      api :GET, '/api/v1/region/:region/zones.json', 'Fetch zones for a single region'
      param :region, String, desc: 'Name of the Region you want to see events for', required: true
      def index
        zones = apply_scopes(Zone)
        return_response(zones, 'zones')
      end
    end
  end
end
