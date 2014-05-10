module Api
  module V1
    class ZonesController < InheritedResources::Base
      respond_to :xml, :json
      has_scope :region

      def index
        zones = apply_scopes(Zone)
        respond_with zones, root: false
      end
    end
  end
end