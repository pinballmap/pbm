module Api
  module V1
    class LocationMachineXrefsController < InheritedResources::Base
      respond_to :json

      def create
        location = params[:location_id]
        machine = params[:machine_id]
        condition = params[:condition]

        lmx = LocationMachineXref.find_by_location_id_and_machine_id(location, machine)
        if (!lmx)
          lmx = LocationMachineXref.create(:location_id => location, :machine_id => machine)
        end

        if (condition)
          lmx.update_condition(condition, {:remote_ip => request.remote_ip})
        end

        return_response(lmx, 'location_machine')
      end

      def update
        lmx = LocationMachineXref.find(params[:id])
        lmx.update_condition(params[:condition], {:remote_ip => request.remote_ip})

        return_response(lmx, 'location_machine')

        rescue ActiveRecord::RecordNotFound
          return_response('Failed to find machine', 'errors')
      end

    end
  end
end
