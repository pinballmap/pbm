class ApiTokenApprovalsController < ApplicationController
  before_action :authenticate_user!
  before_action { authorize! :manage, ApiToken }
  before_action :set_api_token

  def approve
    @api_token.approve!(approved_by: current_user)
    notify_api_token_approved(@api_token)
    redirect_to_admin_edit(notice: "API token approved.")
  rescue ArgumentError => e
    redirect_to_admin_edit(error: e.message)
  end

  def deny
    @api_token.deny!(by: current_user)
    notify_api_token_denied(@api_token)
    redirect_to_admin_edit(notice: "API token request denied.")
  rescue ArgumentError => e
    redirect_to_admin_edit(error: e.message)
  end

  def revoke
    @api_token.revoke!(by: current_user)
    redirect_to_admin_edit(notice: "API token revoked.")
  rescue ArgumentError => e
    redirect_to_admin_edit(error: e.message)
  end

  def regenerate
    new_token = @api_token.regenerate!(by: current_user)
    notify_api_token_approved(new_token)
    redirect_to "/admin/api_token/#{new_token.id}", flash: { notice: "API token regenerated." }
  rescue ArgumentError => e
    redirect_to_admin_edit(error: e.message)
  end

  private

  def set_api_token
    @api_token = ApiToken.find(params[:id])
  end

  def redirect_to_admin_edit(flash_opts)
    redirect_to "/admin/api_token/#{@api_token.id}", flash: flash_opts
  end
end
