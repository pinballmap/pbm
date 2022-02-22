module Api
  module V1
    class OperatorsController < InheritedResources::Base
      skip_before_action :verify_authenticity_token

      before_action :allow_cors
      respond_to :json
      has_scope :region

      api :GET, '/api/v1/operators.json', 'Fetch all operators for all regions'
      api :GET, '/api/v1/region/:region/operators.json', 'Fetch all operators'
      param :region, String, desc: 'Name of the Region you want to see operators for', required: true
      description 'Fetch data about all operators for region'
      formats ['json']
      def index
        operators = apply_scopes(Operator).order('name')
        except = %i[email phone created_at updated_at]

        return_response(operators, 'operators', [], %i[operator_has_email], 200, except)
      end

      api :GET, '/api/v1/operators/:id.json', 'Fetch information for a single operator'
      description 'Returns detail about a single operator'
      param :id, String, desc: 'ID of the Operator you want to see details about', required: true
      def show
        operator = Operator.find(params[:id])

        except = %i[email phone created_at updated_at]

        return_response(operator, 'operator', [], %i[operator_has_email], 200, except)
      rescue ActiveRecord::RecordNotFound
        return_response('Failed to find operator', 'errors')
      end
    end
  end
end
