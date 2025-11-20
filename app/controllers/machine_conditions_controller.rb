class MachineConditionsController < ApplicationController
  before_action :authenticate_user!
  rate_limit to: 50, within: 10.minutes, only: :update

  def destroy
    user = current_user.nil? ? nil : current_user
    mcx = MachineCondition.find(params[:id])
    us = UserSubmission.find_by(machine_condition_id: mcx.id)

    if user && (user.id == mcx.user_id)
      us.deleted_at = Time.now
      us.save
      mcx.destroy
    end

    render nothing: true
  end

  def update
    user = current_user.nil? ? nil : current_user
    mcx = MachineCondition.find(params[:id])
    us = UserSubmission.find_by(machine_condition_id: mcx.id)

    us.update(comment: params[:comment], submission: "#{us.user_name} commented on #{us.machine_name} at #{us.location_name} in #{us.city_name}. They said: #{params[:comment]}") if user && (user.id == us.user_id)

    mcx.update(condition_params) if user && (user.id == mcx.user_id)

    render nothing: true
  end

  private

  def condition_params
    params.permit(:comment)
  end
end
