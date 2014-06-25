module Api
  module V1
    class LocationMachineXrefsController < InheritedResources::Base
      respond_to :json
      has_scope :region, :limit

      api :GET, '/api/v1/region/:region/location_machine_xref.json', "Get all machines at locations in a single region"
      param :region, String, :desc => 'Name of the Region you want to see events for', :required => true
      param :limit, Integer, :desc => 'Limit the number of results that are returned', :required => false
      formats [ 'json' ]
      def index
        lmxes = apply_scopes(LocationMachineXref).order('id desc')
        return_response(lmxes, 'location_machine_xrefs')
      end

      api :POST, '/api/v1/location_machine_xref.json', "Find or create a machine at a location"
      param :location_id, Integer, :desc => 'Location ID to add machine to', :required => true
      param :machine_id, Integer, :desc => 'Machine ID to add to location', :required => true
      param :condition, String, :desc => "Notes on machine's condition", :required => false
      formats [ 'json' ]
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

      api :PUT, '/api/v1/location_machine_xref/:id.json', "Update a machine's condition at a location"
      param :location_machine_xref_id, Integer, :desc => 'Machine at location ID', :required => true
      param :condition, String, :desc => "Notes on machine's condition", :required => true
      formats [ 'json' ]
      def update
        lmx = LocationMachineXref.find(params[:id])
        lmx.update_condition(params[:condition], {:remote_ip => request.remote_ip})

        return_response(lmx, 'location_machine')

        rescue ActiveRecord::RecordNotFound
          return_response('Failed to find machine', 'errors')
      end

      api :DESTROY, '/api/v1/location_machine_xref/:id.json', "Remove a machine from a location"
      param :location_machine_xref_id, Integer, :desc => 'Machine at location ID', :required => true
      formats [ 'json' ]
      def destroy
        lmx = LocationMachineXref.find(params[:id])
        lmx.destroy

        return_response('Successfully deleted lmx #' + lmx.id.to_s, 'msg')

        rescue ActiveRecord::RecordNotFound
          return_response('Failed to find machine', 'errors')
      end

    end
  end
end
