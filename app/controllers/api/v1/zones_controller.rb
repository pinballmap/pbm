module Api
  module V1
    class ZonesController < ApplicationController
      skip_before_action :verify_authenticity_token

      before_action :allow_cors
      has_scope :region

      api :GET, "/api/v1/region/:region/zones.json", "Fetch zones for a single region"
      param :region, String, desc: "Name of the Region you want to see zones for", required: true
      def index
        zones = apply_scopes(Zone)
        return_response(zones, "zones")
      end
    end
  end
end
