module Api
  module V1
    class MachineConditionsController < InheritedResources::Base
      before_filter :allow_cors
      respond_to :json

      api :DESTROY, '/api/v1/machine_conditions/:id.json', 'Remove a machine condition'
      param :id, Integer, desc: 'ID of the machine condition you want to remove', required: true
      formats ['json']
      def destroy
        mc = MachineCondition.find(params[:id])
        mc.destroy

        return_response('Successfully deleted machine condition #' + mc.id.to_s, 'msg')

        rescue ActiveRecord::RecordNotFound
          return_response('Failed to find machine condition', 'errors')
      end
    end
  end
end
