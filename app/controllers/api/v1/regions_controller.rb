module Api
  module V1
    class RegionsController < InheritedResources::Base

      respond_to :xml,:json

      def index
        respond_with(@regions = Region.all,:methods=>[ :primary_email_contact, :all_admin_email_addresses ])
      end

    end
  end
end
