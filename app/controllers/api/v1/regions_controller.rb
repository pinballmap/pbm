module Api
  module V1
    class RegionsController < InheritedResources::Base

      respond_to :xml

      def index
        render xml: Region.all.to_xml(methods: [ :primary_email_contact, :all_admin_email_addresses ])
      end

    end
  end
end
