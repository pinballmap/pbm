module Api
  module V1
    class ZonesController < InheritedResources::Base
      respond_to :json
      has_scope :region

      def index
        zones = apply_scopes(Zone)
        return_response(zones,'zones')
      end
    end
  end
end