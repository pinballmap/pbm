module Api
  module V1
    class RegionLinkXrefsController < InheritedResources::Base
      respond_to :xml, :json
      has_scope :region

      def index
        return_response(apply_scopes(RegionLinkXref),'regionlinks')
      end

    end
  end
end
