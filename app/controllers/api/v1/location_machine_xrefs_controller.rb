module Api
  module V1
    class LocationMachineXrefsController < InheritedResources::Base
      skip_before_action :verify_authenticity_token

      before_action :allow_cors
      respond_to :json
      has_scope :region, :limit

      DEFAULT_TOP_N_MACHINES = 25

      api :GET, '/api/v1/region/:region/location_machine_xrefs.json', 'Get all machines at locations in a single region'
      param :region, String, desc: 'Name of the Region you want to see events for', required: true
      param :limit, Integer, desc: 'Limit the number of results that are returned', required: false
      formats ['json']
      def index
        lmxes = apply_scopes(LocationMachineXref).order('location_machine_xrefs.id desc').includes(:location, :machine, machine_conditions: :user).order('machine_conditions.created_at desc')
        return_response(lmxes, 'location_machine_xrefs', %i[location machine machine_conditions])
      end

      api :GET, '/api/v1/location_machine_xrefs/:id.json', 'Get info about a single lmx'
      param :id, Integer, desc: 'LMX id', required: true
      formats ['json']
      def show
        lmx = LocationMachineXref.find(params[:id])
        return_response(lmx, 'location_machine', [], %i[last_updated_by_username machine_conditions])
      end

      api :POST, '/api/v1/location_machine_xrefs.json', 'Find or create a machine at a location'
      param :location_id, Integer, desc: 'Location ID to add machine to', required: true
      param :machine_id, Integer, desc: 'Machine ID to add to location', required: true
      param :condition, String, desc: "Notes on machine's condition", required: false
      formats ['json']
      def create
        user = current_user.nil? ? nil : current_user

        return return_response(AUTH_REQUIRED_MSG, 'errors') if user.nil?

        location_id = params[:location_id]
        machine_id = params[:machine_id]
        condition = params[:condition]
        status_code = 200

        return return_response('Failed to find machine', 'errors') if machine_id.nil? || location_id.nil? || !Machine.exists?(machine_id) || !Location.exists?(location_id)

        lmx = LocationMachineXref.find_by_location_id_and_machine_id(location_id, machine_id)

        if lmx.nil?
          status_code = 201
          lmx = LocationMachineXref.create(location_id: location_id, machine_id: machine_id, user_id: user ? user.id : nil)
        end

        if condition
          lmx.update_condition(
            condition,
            remote_ip: request.remote_ip,
            request_host: request.host,
            user_agent: request.user_agent,
            user_id: user ? user.id : nil
          )
        end

        return_response(lmx, 'location_machine', [], [:last_updated_by_username], status_code)
      end

      api :PUT, '/api/v1/location_machine_xrefs/:id.json', "Update a machine's condition at a location"
      param :id, Integer, desc: 'LMX id', required: true
      param :condition, String, desc: "Notes on machine's condition", required: true
      formats ['json']
      def update
        lmx = LocationMachineXref.find(params[:id])
        user = current_user.nil? ? nil : current_user

        return return_response(AUTH_REQUIRED_MSG, 'errors') if user.nil?

        lmx.update_condition(
          params[:condition],
          remote_ip: request.remote_ip,
          request_host: request.host,
          user_agent: request.user_agent,
          user_id: user ? user.id : nil
        )

        return_response(lmx, 'location_machine', [], %i[last_updated_by_username machine_conditions])
      rescue ActiveRecord::RecordNotFound
        return_response('Failed to find machine', 'errors')
      end

      api :DESTROY, '/api/v1/location_machine_xrefs/:id.json', 'Remove a machine from a location'
      param :id, Integer, desc: 'LMX id', required: true
      formats ['json']
      def destroy
        lmx = LocationMachineXref.find(params[:id])
        user = current_user.nil? ? nil : current_user

        return return_response(AUTH_REQUIRED_MSG, 'errors') if user.nil?

        lmx.destroy(
          remote_ip: request.remote_ip,
          request_host: request.host,
          user_agent: request.user_agent,
          user_id: user ? user.id : nil
        )

        return_response('Successfully deleted lmx #' + lmx.id.to_s, 'msg')
      rescue ActiveRecord::RecordNotFound
        return_response('Failed to find machine', 'errors')
      end

      api :GET, '/api/v1/location_machine_xrefs/top_n_machines.json', 'Show the top N machines on location'
      param :n, String, desc: 'Number of machines to show', required: false
      formats ['json']
      def top_n_machines
        top_n = params[:n] ||= DEFAULT_TOP_N_MACHINES

        records_array = ActiveRecord::Base.connection.exec_query(<<HERE).to_a
select
  left(m.opdb_id,5) as opdb_id,
  split_part(min(m.name), ' (', 1) as machine_name,
  (array_agg(m.manufacturer ORDER BY m.year ASC))[1] as manufacturer,
  min(m.year) as year,
  count(*) as machine_count
from
  location_machine_xrefs lmx inner join machines m on m.id=lmx.machine_id
group by 1
order by 5 desc
limit #{top_n}
HERE

        return_response(records_array, 'machines')
      end

      api :PUT, '/api/v1/location_machine_xrefs/:id/ic_toggle.json', "Toggle a machine's Insider Connected status"
      # param :id, Integer, desc: 'LMX id', required: true
      formats ['json']
      def ic_toggle
        return return_response(AUTH_REQUIRED_MSG, 'errors') unless current_user

        lmx = LocationMachineXref.find(params[:id])

        success = ActiveRecord::Base.transaction do
          ic_enabled = lmx.ic_enabled || false
          lmx.ic_enabled = !ic_enabled

          lmx.save!

          # update the location's insider connected status if needed
          if lmx.ic_enabled && lmx.location.ic_active != true
            lmx.location.ic_active = true
            lmx.location.save!
          elsif lmx.location.location_machine_xrefs.where(ic_enabled: true).length.zero?
            lmx.location.ic_active = false
            lmx.location.save!
          end

          true
        end

        if success
          return_response(lmx, 'location_machine')
        else
          return_response('Could not update Insider Connect for this machine', 'errors')
        end
      rescue ActiveRecord::RecordNotFound
        return_response('Failed to find machine', 'errors')
      end
    end
  end
end
