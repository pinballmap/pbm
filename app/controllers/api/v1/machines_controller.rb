module Api
  module V1
    class MachinesController < InheritedResources::Base
      skip_before_action :verify_authenticity_token

      before_action :allow_cors
      respond_to :json

      api :GET, '/api/v1/machines.json', 'Fetch all machines'
      description 'These are the canonical machine descriptions, not the location-centric ones'
      param :no_details, Integer, desc: 'Omit unnecessary metadata for initial app loading', required: false
      param :region_id, Integer, desc: 'show only machines from this region', required: false
      param :manufacturer, String, desc: 'show only machines from this manufacturer', required: false
      formats ['json']
      def index
        except = params[:no_details] ? %i[is_active created_at updated_at ipdb_link ipdb_id machine_type machine_display] : nil
        machines = params[:region_id] ? Region.find(params[:region_id]).machines : Machine.all

        machines = machines.select { |m| m.manufacturer == params[:manufacturer] } if params[:manufacturer]

        return_response(machines, 'machines', nil, nil, 200, except)
      end
    end
  end
end
