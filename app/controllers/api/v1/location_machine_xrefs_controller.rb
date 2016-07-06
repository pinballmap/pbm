module Api
  module V1
    class LocationMachineXrefsController < InheritedResources::Base
      before_filter :allow_cors
      respond_to :json
      has_scope :region, :limit

      api :GET, '/api/v1/region/:region/location_machine_xrefs.json', 'Get all machines at locations in a single region'
      param :region, String, desc: 'Name of the Region you want to see events for', required: true
      param :limit, Integer, desc: 'Limit the number of results that are returned', required: false
      formats ['json']
      def index
        lmxes = apply_scopes(LocationMachineXref).order('id desc')
        return_response(lmxes, 'location_machine_xrefs', [], [:location, :machine, :machine_conditions])
      end

      api :POST, '/api/v1/location_machine_xrefs.json', 'Find or create a machine at a location'
      param :location_id, Integer, desc: 'Location ID to add machine to', required: true
      param :machine_id, Integer, desc: 'Machine ID to add to location', required: true
      param :condition, String, desc: "Notes on machine's condition", required: false
      formats ['json']
      def create
        location_id = params[:location_id]
        machine_id = params[:machine_id]
        condition = params[:condition]
        status_code = 200

        if machine_id.nil? || location_id.nil? || !Machine.exists?(machine_id) || !Location.exists?(location_id)
          return return_response('Failed to find machine', 'errors')
        end

        lmx = LocationMachineXref.find_by_location_id_and_machine_id(location_id, machine_id)

        if lmx.nil?
          status_code = 201
          lmx = LocationMachineXref.create(location_id: location_id, machine_id: machine_id)
        end

        if condition
          lmx.update_condition(condition, remote_ip: request.remote_ip, request_host: request.host, user_agent: request.user_agent)
        end

        return_response(lmx, 'location_machine', [], [], status_code)
      end

      api :PUT, '/api/v1/location_machine_xrefs/:id.json', "Update a machine's condition at a location"
      param :id, Integer, desc: 'LMX id', required: true
      param :condition, String, desc: "Notes on machine's condition", required: true
      formats ['json']
      def update
        lmx = LocationMachineXref.find(params[:id])
        lmx.update_condition(params[:condition], remote_ip: request.remote_ip, request_host: request.host, user_agent: request.user_agent)

        return_response(lmx, 'location_machine', [], [:machine_conditions])

        rescue ActiveRecord::RecordNotFound
          return_response('Failed to find machine', 'errors')
      end

      api :DESTROY, '/api/v1/location_machine_xrefs/:id.json', 'Remove a machine from a location'
      param :id, Integer, desc: 'LMX id', required: true
      formats ['json']
      def destroy
        lmx = LocationMachineXref.find(params[:id])
        lmx.destroy(remote_ip: request.remote_ip, request_host: request.host, user_agent: request.user_agent)

        return_response('Successfully deleted lmx #' + lmx.id.to_s, 'msg')

        rescue ActiveRecord::RecordNotFound
          return_response('Failed to find machine', 'errors')
      end
    end
  end
end
