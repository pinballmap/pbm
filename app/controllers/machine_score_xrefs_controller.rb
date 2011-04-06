class MachineScoreXrefsController < InheritedResources::Base
  respond_to :xml, :json, :html, :js, :rss
  has_scope :region

  def create
    msx = MachineScoreXref.create(:location_machine_xref_id => params[:location_machine_xref_id])
    msx.score = params[:score]
    msx.user = current_user
    msx.rank = params[:rank]

    msx.save
    msx.sanitize_scores
  end

  def index
    @lmxs = apply_scopes(LocationMachineXref).includes([:machine_score_xrefs, :location, :machine])

    @msxs = Array.new

    @lmxs.each do |lmx|
      @msxs << lmx.machine_score_xrefs unless lmx.machine_score_xrefs.empty?
    end

    if (!@msxs.empty?)
      @msxs.flatten!
      @msxs.sort! {|a, b| b.created_at <=> a.created_at}
    end

    respond_with(@msxs)
  end
end
