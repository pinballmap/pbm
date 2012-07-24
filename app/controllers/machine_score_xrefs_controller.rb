class MachineScoreXrefsController < InheritedResources::Base
  respond_to :xml, :json, :html, :js, :rss
  has_scope :region

  def create
    msx = MachineScoreXref.create(:location_machine_xref_id => params[:location_machine_xref_id])

    score = params[:score]
    score.gsub!(/[^0-9]/,'')

    msx.score = score
    msx.user = current_user
    msx.rank = params[:rank]
    msx.initials = params[:initials]

    msx.save
    msx.sanitize_scores
  end

  def index
    @msxs = apply_scopes(MachineScoreXref).order('machine_score_xrefs.id desc').limit(50).includes([:location_machine_xref, :location, :machine])

    respond_with(@msxs)
  end
end
