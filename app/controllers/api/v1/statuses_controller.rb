module Api
  module V1
    class StatusesController < InheritedResources::Base
      skip_before_action :verify_authenticity_token

      before_action :allow_cors
      respond_to :json

      api :GET, "/api/v1/statuses.json", "Fetch table statuses"
      formats ["json"]
      def index
        return_response(Status.all, "statuses")
      end
    end
  end
end
