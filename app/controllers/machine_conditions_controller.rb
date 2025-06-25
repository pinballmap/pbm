class MachineConditionsController < ApplicationController
  before_action :authenticate_user!
  rate_limit to: 50, within: 10.minutes, only: :update

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
