module Api
  module V1
    class MachineConditionsController < InheritedResources::Base
      skip_before_action :verify_authenticity_token
      before_action :allow_cors
      respond_to :json

      api :PUT, "/api/v1/machine_conditions/:id.json", "Update attributes on a machine condition"
      param :id, Integer, desc: "ID of machine condition", required: true
      param :comment, String, desc: "Updated condition", required: true
      formats [ "json" ]
      def update
        machine_condition = MachineCondition.find(params[:id])

        user = current_user.nil? ? nil : current_user
        return return_response(AUTH_REQUIRED_MSG, "errors") if user.nil?

        if machine_condition.user == user
          machine_condition.update({ comment: params[:comment] })
          return_response("Successfully updated machine condition", "machine_condition")
        else
          return_response("You can only update machine conditions that you own", "errors")
        end
      rescue ActiveRecord::RecordNotFound
        return_response("Failed to find machine condition", "errors")
      end

      api :DESTROY, "/api/v1/machine_conditions/:id.json", "Destroy a single machine condition"
      description "Destroys a single machine condition"
      param :id, String, desc: "ID of the MachineCondition you want to destroy", required: true
      def destroy
        machine_condition = MachineCondition.find(params[:id])

        user = current_user.nil? ? nil : current_user
        return return_response(AUTH_REQUIRED_MSG, "errors") if user.nil?

        if machine_condition.user == user
          machine_condition.destroy
          return_response("Successfully removed machine condition", "machine_condition")
        else
          return_response("You can only delete machine conditions that you own", "errors")
        end
      rescue ActiveRecord::RecordNotFound
        return_response("Failed to find machine condition", "errors")
      end
    end
  end
end
