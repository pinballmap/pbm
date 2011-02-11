class MachineScoreXrefsController < InheritedResources::Base
  def create
    msx = MachineScoreXref.create(:location_machine_xref_id => params[:location_machine_xref_id])
    msx.score = params[:score]
    msx.initials = params[:initials]
    msx.rank = params[:rank]

    msx.save
    msx.sanitize_scores
  end
end
