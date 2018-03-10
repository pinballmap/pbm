module Api
  module V1
    class RegionLinkXrefsController < InheritedResources::Base
      before_action :allow_cors
      respond_to :json
      has_scope :region

      api :GET, '/api/v1/region/:region/region_link_xrefs.json', 'Fetch all region-centric web sites'
      param :region, String, desc: 'Name of the Region you want to see events for', required: true
      def index
        return_response(apply_scopes(RegionLinkXref), 'regionlinks')
      end
    end
  end
end
