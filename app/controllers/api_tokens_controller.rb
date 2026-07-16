class ApiTokensController < ApplicationController
  before_action :authenticate_user!, except: [ :show ]

  def show
    @api_token = ApiToken.where(user: current_user).order(created_at: :desc).first if current_user
  end

  def create
    if requesting_blocked?
      redirect_to api_token_path, flash: { error: "You cannot submit a new API token request right now." }
      return
    end

    api_token = ApiToken.new(user: current_user, requested_use: token_params[:requested_use])

    if api_token.save
      notify_super_admins_of_api_token_request(api_token)
      redirect_to api_token_path, flash: { notice: "Your API token request has been submitted." }
    else
      redirect_to api_token_path, flash: { error: api_token.errors.full_messages.join(", ") }
    end
  end

  def regenerate
    api_token = ApiToken.where(user: current_user).active.first

    unless api_token
      redirect_to api_token_path, flash: { error: "You don't have an active API token to regenerate." }
      return
    end

    new_token = api_token.regenerate!(by: current_user)
    notify_api_token_approved(new_token)
    redirect_to api_token_path, flash: { notice: "Your API token has been regenerated." }
  end

  private

  def token_params
    params.require(:api_token).permit(:requested_use)
  end

  def requesting_blocked?
    latest = ApiToken.where(user: current_user).order(created_at: :desc).first
    latest.present? && (latest.pending? || latest.active? || latest.revoked?)
  end
end
