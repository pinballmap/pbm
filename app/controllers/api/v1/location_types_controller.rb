module Api
  module V1
    class LocationTypesController < InheritedResources::Base

      respond_to :xml, :json

      def index
        respond_with LocationType.all
      end

    end
  end
end
