module Api
  module V1
    class RegionsController < InheritedResources::Base

      respond_to :json

      def index
        regions = Region.all

        return_response(regions, 'regions', [], [:primary_email_contact,:all_admin_email_addresses])
      end

    end
  end
end
