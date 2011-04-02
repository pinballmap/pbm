class MachineScoreXrefsController < InheritedResources::Base
  respond_to :xml, :json, :html, :js, :rss

  def create
    msx = MachineScoreXref.create(:location_machine_xref_id => params[:location_machine_xref_id])
    msx.score = params[:score]
    msx.user = current_user
    msx.rank = params[:rank]

    msx.save
    msx.sanitize_scores
  end

  def index
    @msxs = apply_scopes(MachineScoreXref).includes(:location)
    respond_with(@msxs)
  end
end
