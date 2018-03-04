module Api
  module V1
    class MachinesController < InheritedResources::Base
      before_action :allow_cors
      respond_to :json

      api :GET, '/api/v1/machines.json', 'Fetch all machines'
      description 'These are the canonical machine descriptions, not the location-centric ones'
      param :no_details, Integer, desc: 'Omit unnecessary metadata for initial app loading', required: false
      param :region_id, Integer, desc: 'show only machines from this region', required: false
      formats ['json']
      def index
        except = params[:no_details] ? %i[is_active created_at updated_at ipdb_link ipdb_id machine_group_id] : nil
        machines = params[:region_id] ? Region.find(params[:region_id]).machines : Machine.all

        return_response(machines, 'machines', nil, nil, 200, except)
      end

      api :POST, '/api/v1/machines.json', 'Create a new canonical machine'
      description 'This does not create a machine at a location, it just creates the new canonical machine unless it already exists in the system'
      param :machine_name, String, desc: 'Name of the new canonical machine', required: false
      param :location_id, Integer, desc: 'Location ID of where the machine was added', required: false
      formats ['json']
      def create
        user = current_user.nil? ? nil : current_user

        return return_response(AUTH_REQUIRED_MSG, 'errors') if user.nil?

        machine_name = params[:machine_name]
        machine_name.strip!

        machine = Machine.where(['lower(name) = ?', machine_name.downcase]).first
        location = Location.find(params[:location_id])

        if machine.nil?
          machine = Machine.create(name: machine_name)

          send_new_machine_notification(machine, location, current_user.nil? ? nil : current_user)
          return_response(machine, 'machine', [], [], 201)
        else
          return_response('Machine already exists', 'errors')
        end
      rescue ActiveRecord::RecordNotFound
        return_response('Failed to find location', 'errors')
      end
    end
  end
end
