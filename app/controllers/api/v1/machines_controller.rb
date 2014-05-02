module Api
  module V1
    class MachinesController < InheritedResources::Base

      respond_to :xml, :json

      def index
        respond_with Machine.all, :root => false
      end

    end
  end
end
