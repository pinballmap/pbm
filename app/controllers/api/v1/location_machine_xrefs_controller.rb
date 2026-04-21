module Api
  module V1
    class LocationMachineXrefsController < ApplicationController
      skip_before_action :verify_authenticity_token

      before_action :allow_cors
      has_scope :region, :limit

      rate_limit to: 100, within: 10.minutes, only: :destroy
      rate_limit to: 50, within: 10.minutes, only: :update
      rate_limit to: 120, within: 1.minute, only: :index

      DEFAULT_TOP_N_MACHINES = 25
      DEFAULT_MOST_RECENT_MACHINES = 3
      MAX_MILES_TO_SEARCH_FOR_CLOSEST_LOCATION = 50

      api :GET, "/api/v1/region/:region/location_machine_xrefs.json", "Get all machines at locations in a single region. This is a legacy endpoint, and it was very bloated and has since been reduced. It is better to use the locations.json endpoint if you want more location and machine info"
      param :region, String, desc: "Name of the Region you want to see machines for", required: true
      formats [ "json" ]
      def index
        lmxes = apply_scopes(LocationMachineXref).order("location_machine_xrefs.id desc")

        return_response(lmxes, "location_machine_xrefs", [], [], 200, [ :deleted_at, :user_id ])
      end

      api :GET, "/api/v1/location_machine_xrefs/:id.json", "Get info about a single lmx"
      param :id, Integer, desc: "The location machine ID (LMX ID)", required: true
      param :user_id, Integer, desc: "Limits scores (not comments) to a single user. If user ID param is 0, excludes all scores.", required: false
      formats [ "json" ]
      def show
        if params[:user_id] == "0"
          lmx = LocationMachineXref.includes(:machine).find(params[:id])

          methods = [ sorted_machine_conditions: { methods: %i[username operator_id admin_title contributor_rank] } ]

          lmx_json = lmx.as_json(include: methods, methods: [ :machine ], root: false).merge("machine_score_xrefs" => [])
          render json: { "location_machine" => lmx_json }
          return
        elsif params[:user_id].present?
          lmx = LocationMachineXref.includes({ machine_score_xrefs: :user }, :machine).order("machine_score_xrefs.score DESC").find(params[:id])
          lmx.machine_score_xrefs.load.target.select! { |msx| msx.user_id == params[:user_id].to_i }

          methods = [ sorted_machine_conditions: { methods: %i[username operator_id admin_title contributor_rank] }, machine_score_xrefs: { methods: %i[username operator_id admin_title contributor_rank] } ]
        else
          lmx = LocationMachineXref.includes({ machine_score_xrefs: :user }, :machine).order("machine_score_xrefs.score DESC").find(params[:id])

          methods = [ sorted_machine_conditions: { methods: %i[username operator_id admin_title contributor_rank] }, machine_score_xrefs: { methods: %i[username operator_id admin_title contributor_rank] } ]
        end

        return_response(
          lmx,
          "location_machine",
          methods,
          [ :machine ]
        )

      rescue ActiveRecord::RecordNotFound
        return_response("Failed to find machine", "errors")
      end

      api :POST, "/api/v1/location_machine_xrefs.json", "Find or create a machine at a location"
      param :location_id, Integer, desc: "Location ID to add machine to", required: true
      param :machine_id, Integer, desc: "Machine ID to add to location", required: true
      param :condition, String, desc: "Notes on machine's condition", required: false
      formats [ "json" ]
      def create
        return unless (user = require_api_user)

        location_id = params[:location_id].to_i
        machine_id = params[:machine_id].to_i
        condition = params[:condition]
        status_code = 200

        return return_response("Failed to find machine", "errors") if machine_id.zero? || location_id.zero? || !Machine.exists?(machine_id) || !Location.exists?(location_id)

        lmx = LocationMachineXref.unscoped.where([ "location_id = ? and machine_id = ?", location_id, machine_id ]).where.not(deleted_at: nil).where(deleted_at: 7.days.ago..Time.current).order(updated_at: :desc).first

        if lmx
          lmx.deleted_at = nil
          lmx.user_id = user.id
          lmx.save
          Location.increment_counter(:machine_count, location_id)
          lmx.create_user_submission
          if lmx.location.location_machine_xrefs.where(ic_enabled: true).present? && lmx.location.ic_active == false
            lmx.location.ic_active = true
          end
          lmx.location.date_last_updated = Date.today
          lmx.location.last_updated_by_user_id = user&.id
          lmx.location.save(validate: false)
        else
          lmx = LocationMachineXref.find_by_location_id_and_machine_id(location_id, machine_id)
          if lmx.nil?
            status_code = 201
            lmx = LocationMachineXref.create(location_id: location_id, machine_id: machine_id, user_id: user&.id)
          end
        end

        if condition
          lmx.update_condition(
            condition,
            user_id: user&.id
          )
        end

        return_response(lmx, "location_machine", [], [ :last_updated_by_username ], status_code)
      end

      api :PUT, "/api/v1/location_machine_xrefs/:id.json", "Update a machine's condition at a location"
      param :id, Integer, desc: "LMX id", required: true
      param :condition, String, desc: "Notes on machine's condition", required: true
      formats [ "json" ]
      def update
        lmx = LocationMachineXref.find(params[:id])
        return unless (user = require_api_user)

        lmx.update_condition(
          params[:condition],
          user_id: user&.id
        )

        return_response(lmx, "location_machine", [], %i[last_updated_by_username sorted_machine_conditions])
      rescue ActiveRecord::RecordNotFound
        return_response("Failed to find machine", "errors")
      end

      api :DESTROY, "/api/v1/location_machine_xrefs/:id.json", "Remove a machine from a location"
      param :id, Integer, desc: "LMX id", required: true
      formats [ "json" ]
      def destroy
        lmx = LocationMachineXref.find(params[:id])
        return unless (user = require_api_user)

        lmx.deleted_at = Time.now
        lmx.save

        lmx.destroy({ user_id: user&.id })

        return_response("Successfully deleted lmx #" + lmx.id.to_s, "msg")
      rescue ActiveRecord::RecordNotFound
        return_response("Failed to find machine", "errors")
      end

      api :GET, "/api/v1/location_machine_xrefs/top_n_machines.json", "Show the top N machines on location"
      param :n, String, desc: "Number of machines to show", required: false
      formats [ "json" ]
      def top_n_machines
        top_n = params[:n].to_i.zero? ? DEFAULT_TOP_N_MACHINES : params[:n].to_i

        records_request = ActiveRecord::Base.connection.exec_query(<<HERE).to_a
select
  left(m.opdb_id,5) as opdb_id,
  split_part(min(m.name), ' (', 1) as machine_name,
  (array_agg(m.manufacturer ORDER BY m.year ASC))[1] as manufacturer,
  min(m.year) as year,
  count(*) as machine_count
from
  location_machine_xrefs lmx inner join machines m on m.id=lmx.machine_id
  where m.opdb_id is not null
group by 1
order by 5 desc
limit #{top_n}
HERE

        if top_n == DEFAULT_TOP_N_MACHINES
          records_array = Rails.cache.fetch("top_25_cache", expires_in: 1.hour) do
            records_request
          end
        else
          records_array = records_request
        end

        return_response(records_array, "machines")
      end

      api :GET, "/api/v1/location_machine_xrefs/most_recent_by_lat_lon.json", "Returns the most recently added machines near transmitted lat/lon"
      description "This sends you the most recent machines added near your lat/lon (defaults to within #{MAX_MILES_TO_SEARCH_FOR_CLOSEST_LOCATION} miles)."
      param :lat, String, desc: "Latitude", required: true
      param :lon, String, desc: "Longitude", required: true
      param :max_distance, String, desc: 'Closest location within "max_distance" miles, with a max of 500', required: false
      formats [ "json" ]
      def most_recent_by_lat_lon
        if params[:max_distance].blank?
          max_distance = MAX_MILES_TO_SEARCH_FOR_CLOSEST_LOCATION
        elsif params[:max_distance].to_i > 500
          max_distance = 500
        else
          max_distance = params[:max_distance].to_i
        end

        closest_locations = apply_scopes(Location).includes(:machines).near([ params[:lat], params[:lon] ], max_distance).uniq

        last_n_machines_added = {}
        closest_locations.each do |l|
          l.location_machine_xrefs.each do |lmx|
            last_n_machines_added[lmx.created_at] = "#{lmx.machine.name} @ #{l.name}"
          end
        end

        if !closest_locations.empty?
          return_response(last_n_machines_added.sort.last(DEFAULT_MOST_RECENT_MACHINES).collect { |a| a[1] }, "most_recently_added_machines", [], %i[], 200)
        else
          return_response("No locations within #{max_distance} miles.", "errors")
        end
      end

      api :PUT, "/api/v1/location_machine_xrefs/:location_machine_xref_id/ic_toggle.json", "Toggle a machine's Insider Connected status"
      param :location_machine_xref_id, Integer, desc: "LMX id", required: true
      param :ic_enabled, [ true, false ], desc: "Sets the Insider Connected status for this machine", required: false
      formats [ "json" ]
      def ic_toggle
        return unless (user = require_api_user)

        lmx = LocationMachineXref.find(params[:location_machine_xref_id])
        if lmx.machine.ic_eligible

          success = ActiveRecord::Base.transaction do
            if params.key?(:ic_enabled)
              lmx.update!(ic_enabled: params[:ic_enabled])
            else
              ic_enabled = lmx.ic_enabled || false
              lmx.ic_enabled = !ic_enabled
              lmx.save!
            end

            lmx.create_ic_user_submission!(user)

            # update the location's insider connected status if needed
            if lmx.ic_enabled && lmx.location.ic_active != true
              lmx.location.ic_active = true
              lmx.location.save!
            elsif lmx.location.location_machine_xrefs.where(ic_enabled: true).blank?
              lmx.location.ic_active = false
              lmx.location.save!
            end

            true
          end
        end

        if success
          return_response(lmx, "location_machine")
        else
          return_response("Could not update Insider Connected for this machine", "errors")
        end
      rescue ActiveRecord::RecordNotFound
        return_response("Failed to find machine", "errors")
      end
    end
  end
end
