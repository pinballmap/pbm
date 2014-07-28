module Api
  module V1
    class MachineScoreXrefsController < InheritedResources::Base
      before_filter :allow_cors
      respond_to :json
      has_scope :region, :limit

      api :GET, '/api/v1/region/:region/machine_score_xrefs.json', "Fetch all high scores for a region"
      param :region, String, :desc => 'Name of the Region you want to see events for', :required => true
      param :limit, Integer, :desc => 'Limit number of results returned', :required => false
      formats [ 'json' ]
      def index
        scores = apply_scopes(MachineScoreXref).order('id desc')
        return_response(scores, 'machine_score_xrefs')
      end

      api :POST, '/api/v1/machine_score_xrefs.json', "Enter a new high score for a machine"
      param :location_machine_xref_id, Integer, :desc => 'Location machine identifier for high score', :required => true
      param :score, String, :desc => 'A pinball machine high score', :required => false
      param :rank, Integer, :desc => 'The rank on the machine, GC is 1, 1st is 2, etc.', :required => false
      param :initials, String, :desc => 'Initials of the high score holder', :required => false
      formats [ 'json' ]
      def create
        lmx = LocationMachineXref.find(params[:location_machine_xref_id])

        msx = MachineScoreXref.create(:location_machine_xref_id => lmx.id)

        score = params[:score]
        score.gsub!(/[^0-9]/,'')

        msx.score = score
        msx.rank = params[:rank]
        msx.initials = params[:initials]

        if (msx.save)
          msx.sanitize_scores
          return_response('Added your score!', 'msg')
        else
          return_response(msx.errors.full_messages, 'errors')
        end

        rescue ActiveRecord::RecordNotFound
          return_response('Failed to find machine', 'errors')
      end

      api :GET, '/api/v1/machine_score_xrefs/:id.json', "View all high scores for a location's machine"
      param :id, Integer, :desc => 'The location machine ID, NOT the machine score ID', :required => true
      formats [ 'json' ]
      def show
        lmx = LocationMachineXref.find(params[:id])

        msxes = MachineScoreXref.where(location_machine_xref_id: lmx.id).order(:rank)
        return_response(msxes, 'machine_scores')

        rescue ActiveRecord::RecordNotFound
          return_response('Failed to find machine', 'errors')
      end

    end
  end
end
