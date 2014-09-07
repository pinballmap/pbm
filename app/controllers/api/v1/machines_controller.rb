module Api
  module V1
    class MachinesController < InheritedResources::Base
      before_filter :allow_cors
      respond_to :json

      api :GET, '/api/v1/machines.json', 'Fetch all machines'
      description 'These are the canonical machine descriptions, not the location-centric ones'
      formats ['json']
      def index
        return_response(Machine.all, 'machines')
      end

      api :POST, '/api/v1/machines.json', 'Create a new canonical machine'
      description 'This does not create a machine at a location, it just creates the new canonical machine unless it already exists in the system'
      param :machine_name, String, desc: 'Name of the new canonical machine', required: false
      param :location_id, Integer, desc: 'Location ID of where the machine was added', required: false
      formats ['json']
      def create
        machine_name = params[:machine_name]
        machine_name.strip!

        machine = Machine.where(['lower(name) = ?', machine_name.downcase]).first
        location = Location.find(params[:location_id])

        if machine.nil?
          machine = Machine.create(name: machine_name)
          send_new_machine_notification(machine, location)
          return_response(machine, 'machine')
        else
          return_response('Machine already exists', 'errors')
        end

        rescue ActiveRecord::RecordNotFound
          return_response('Failed to find location', 'errors')
      end
    end
  end
end
