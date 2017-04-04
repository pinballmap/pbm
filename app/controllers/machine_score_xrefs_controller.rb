class MachineScoreXrefsController < InheritedResources::Base
  respond_to :xml, :json, :html, :js, :rss
  has_scope :region

  def create
    score = params[:score]

    return if score.nil? || score.empty?

    score.gsub!(/[^0-9]/, '')

    return if score.nil? || score.empty? || score.to_i.zero?

    msx = MachineScoreXref.create(location_machine_xref_id: params[:location_machine_xref_id])

    msx.score = score
    msx.user = current_user
    msx.save
    msx.create_user_submission

    render nothing: true
  end

  def index
    @msxs = apply_scopes(MachineScoreXref).order('machine_score_xrefs.id desc').limit(50).includes([:location_machine_xref, :location, :machine])

    respond_with(@msxs)
  end
end
