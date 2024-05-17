class MachineConditionsController < InheritedResources::Base
  respond_to :xml, :json, :html, :js, :rss
  before_action :authenticate_user!, except: %i[index show]

  def destroy
    user = current_user.nil? ? nil : current_user
    mcx = MachineCondition.find(params[:id])

    mcx.destroy if user && (user.id == mcx.user_id)

    render nothing: true
  end

  def update
    user = current_user.nil? ? nil : current_user
    mcx = MachineCondition.find(params[:id])

    mcx.update(condition_params) if user && (user.id == mcx.user_id)

    render nothing: true
  end

  private

  def condition_params
    params.permit(:comment)
  end
end
