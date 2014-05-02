module Api
  module V1
    class RegionsController < InheritedResources::Base

      respond_to :xml,:json

      def index
        respond_with(Region.all,:methods=>[ :primary_email_contact, :all_admin_email_addresses ],:root => false)
      end

    end
  end
end
