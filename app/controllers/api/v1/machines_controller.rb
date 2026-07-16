module Api
  module V1
    class MachinesController < BaseController
      before_action :allow_cors

      api :GET, "/api/v1/machines.json", "Fetch all machines"
      description "These are the canonical machine descriptions, not the location-centric ones"
      param :no_details, Integer, desc: "Omit unnecessary metadata for initial app loading", required: false
      param :region_id, Integer, desc: "show only machines from this region", required: false
      param :machine_group_id, Integer, desc: "show only machines from machine group id", required: false
      param :id, Integer, desc: "show only this machine", required: false
      param :manufacturer, String, desc: "show only machines from this manufacturer", required: false
      param :lmx_count, Integer, desc: "include lmx_count (count of locations with machine) alongside no_details", required: false
      formats [ "json" ]
      def index
        if params[:no_details] && !params[:region_id] && !params[:manufacturer] && !params[:machine_group_id] && !params[:id]
          cache_key = params[:lmx_count] ? Machine::MOBILE_CACHE_KEY_WITH_LMX_COUNT : Machine::MOBILE_CACHE_KEY

          json = Rails.cache.fetch(cache_key, expires_in: 1.week) do
            except = %i[is_active created_at updated_at ipdb_id machine_display]
            except << :lmx_count unless params[:lmx_count]
            { machines: Machine.all.as_json(except: except) }.to_json
          end
          render json: json
          return
        end

        except = params[:no_details] ? %i[is_active created_at updated_at ipdb_id machine_display] : nil
        except << :lmx_count if except && !params[:lmx_count]
        machines = params[:region_id] ? Region.find(params[:region_id]).machines : Machine.all

        machines = machines.select { |m| m.manufacturer == params[:manufacturer] } if params[:manufacturer]

        machines = Machine.where(machine_group_id: params[:machine_group_id]) if params[:machine_group_id]

        machines = Machine.where(id: params[:id]) if params[:id]

        return_response(machines, "machines", nil, nil, 200, except)
      end
    end
  end
end
