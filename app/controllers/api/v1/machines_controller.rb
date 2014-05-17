module Api
  module V1
    class MachinesController < InheritedResources::Base

      respond_to :json

      def index
        return_response(Machine.all, 'machines')
      end

      def create
        machine_name = params[:machine_name]

        machine = Machine.find(:first, :conditions => ["lower(name)= ?", machine_name.downcase])
        location = Location.find(params[:location_id])

        if (machine.nil?)
          machine = Machine.create(:name => machine_name)
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
