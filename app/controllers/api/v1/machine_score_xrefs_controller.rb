module Api
  module V1
    class MachineScoreXrefsController < InheritedResources::Base
      respond_to :json
      has_scope :region

      def create
        msx = MachineScoreXref.create(:location_machine_xref_id => params[:location_machine_xref_id])
        score = params[:score]
        score.gsub!(/[^0-9]/,'')
        msx.score = score
        msx.rank = params[:rank]
        msx.initials = params[:initials]
        if (msx.save) 
          msx.sanitize_scores
          return_response('Added your score!', 'response')
        else
          return_response(msx.errors.full_messages, 'errors')
        end

        rescue ActiveRecord::RecordNotFound
          return_response('Failed to find machine', 'errors')
      end

      def show
        msx = MachineScoreXref.where(location_machine_xref_id: params[:id])
        return_response(msx, 'machine_scores')

        rescue ActiveRecord::RecordNotFound
          return_response('Failed to find machine', 'errors')

      end

    end
  end
end