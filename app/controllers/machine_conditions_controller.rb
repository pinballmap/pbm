class MachineConditionsController < InheritedResources::Base
  respond_to :xml, :json, :html, :js, :rss

  def destroy
    mcx = MachineCondition.find(params[:id])
    mcx.destroy

    render nothing: true
  end

end