class UserMachineXrefsController < ApplicationController
  before_action :authenticate_user!

  def create
    Array(params[:machine_id]).each do |machine_id|
      UserMachineXref.find_or_create_by(user: current_user, machine_id: machine_id)
    end
    render nothing: true
  end

  def destroy
    umx = UserMachineXref.find(params[:id])

    if current_user.id == umx.user_id
      if MachineScoreXref.where(user: current_user, machine_id: umx.machine_id).exists?
        render json: { errors: "Cannot remove a machine that has scores from your list" }, status: :unprocessable_content
        return
      end

      umx.destroy
    end

    render nothing: true
  end
end
