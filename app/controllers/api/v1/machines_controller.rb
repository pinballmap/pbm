module Api
  module V1
    class MachinesController < InheritedResources::Base

      respond_to :xml, :json

      def index
        return_response(Machine.all,'machines')
      end

    end
  end
end
