module Api
  module V1
    class MachineScoreXrefsController < InheritedResources::Base
      respond_to :json
      has_scope :region, :limit

      def index
        scores = apply_scopes(MachineScoreXref).order('id desc')
        return_response(scores, 'machine_score_xrefs')
      end

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

      def show
        lmx = LocationMachineXref.find(params[:id])

        msxes = MachineScoreXref.where(location_machine_xref_id: lmx.id)
        return_response(msxes, 'machine_scores')

        rescue ActiveRecord::RecordNotFound
          return_response('Failed to find machine', 'errors')
      end

    end
  end
end
