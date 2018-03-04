module Api
  module V1
    class MachineScoreXrefsController < InheritedResources::Base
      before_action :allow_cors
      respond_to :json
      has_scope :region, :limit, :zone_id

      api :GET, '/api/v1/region/:region/machine_score_xrefs.json', 'Fetch all high scores for a region'
      param :region, String, desc: 'Name of the Region you want to see scores for', required: true
      param :zone_id, Integer, desc: 'ID of the zone you want to see scores for', required: false
      param :limit, Integer, desc: 'Limit number of results returned', required: false
      formats ['json']
      def index
        scores = apply_scopes(MachineScoreXref).order('id desc')
        return_response(scores, 'machine_score_xrefs', [], [:username])
      end

      api :POST, '/api/v1/machine_score_xrefs.json', 'Enter a new high score for a machine'
      param :location_machine_xref_id, Integer, desc: 'Location machine identifier for high score', required: true
      param :score, String, desc: 'A pinball machine high score', required: false
      formats ['json']
      def create
        user = current_user.nil? ? nil : current_user

        return return_response(AUTH_REQUIRED_MSG, 'errors') if user.nil?

        score = params[:score]

        if score.nil? || score.empty?
          return_response('Score can not be blank and must be a numeric value', 'errors')
          return
        end

        score.gsub!(/[^0-9]/, '')

        if score.nil? || score.empty? || score.to_i.zero?
          return_response('Score can not be blank and must be a numeric value', 'errors')
          return
        end

        lmx = LocationMachineXref.find(params[:location_machine_xref_id])

        msx = MachineScoreXref.create(location_machine_xref_id: lmx.id)

        msx.score = score
        msx.user = user

        if msx.save
          msx.create_user_submission
          return_response(msx, 'machine_score_xref', [], [:username], 201)
        else
          return_response(msx.errors.full_messages, 'errors')
        end
      rescue ActiveRecord::RecordNotFound
        return_response('Failed to find machine', 'errors')
      rescue RangeError
        return_response('Number is too large. Please enter a valid score.', 'errors')
      end

      api :GET, '/api/v1/machine_score_xrefs/:id.json', "View all high scores for a location's machine"
      param :id, Integer, desc: 'The location machine ID, NOT the machine score ID', required: true
      formats ['json']
      def show
        lmx = LocationMachineXref.find(params[:id])

        msxes = MachineScoreXref.where(location_machine_xref_id: lmx.id).order('score desc')
        return_response(msxes, 'machine_scores', [], [:username])
      rescue ActiveRecord::RecordNotFound
        return_response('Failed to find machine', 'errors')
      end
    end
  end
end
