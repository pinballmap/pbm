module Api
  module V1
    class LocationMachineXrefsController < InheritedResources::Base
      respond_to :xml, :json

      def create
        location = params[:location_id]
        machine = params[:machine_id]
        condition = params[:condition]

        # Check if machine already exists at location.
        lmx = LocationMachineXref.find_by_location_id_and_machine_id(location,machine)
        if (!lmx)
          lmx = LocationMachineXref.create(:location_id => location, :machine_id => machine)
        end
        # If condition is set we update the condition of the machine.
        if (condition)
          lmx.update_condition(condition, {:remote_ip => request.remote_ip})
        end

        respond_with(lmx) do |format|
          format.json{render json: lmx}
          format.xml{render xml: lmx}
        end
        
      end

      def update
        lmx = LocationMachineXref.find(params[:id])
        lmx.update_condition(params[:condition], {:remote_ip => request.remote_ip})

        respond_with(lmx) do |format|
          format.json{render json: lmx}
          format.xml{render xml: lmx}
        end
      end

    end
  end
end