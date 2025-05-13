module Api
  module V1
    class MachineGroupsController < ApplicationController
      skip_before_action :verify_authenticity_token

      before_action :allow_cors

      api :GET, "/api/v1/machine_groups.json", "Fetch all machine groups"
      description "Machine group IDs"
      formats [ "json" ]
      def index
        return_response(MachineGroup.all, "machine_groups", nil, nil, 200)
      end
    end
  end
end
