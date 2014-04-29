module Api
  module V1
    class RegionLinkXrefsController < InheritedResources::Base
      respond_to :xml, :json
      has_scope :region

      def index
        respond_with apply_scopes(RegionLinkXref)
      end

    end
  end
end
