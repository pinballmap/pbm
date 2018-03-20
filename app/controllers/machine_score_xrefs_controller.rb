class MachineScoreXrefsController < InheritedResources::Base
  respond_to :xml, :json, :html, :js, :rss
  has_scope :region
  before_action :authenticate_user!, only: %i[create update]

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
    @msxs = apply_scopes(MachineScoreXref).order('machine_score_xrefs.id desc').limit(50).includes(%i[location_machine_xref location machine])

    respond_with(@msxs)
  end

  private

  def machine_score_xref_params
    params.require(:machine_score_xref).permit(:score, :location_machine_xref_id)
  end
end
