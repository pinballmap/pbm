class MachineConditionsController < InheritedResources::Base
  respond_to :xml, :json, :html, :js, :rss

  def create
    @machine_condition = MachineCondition.new(machine_condition_params)
    if @machine_condition.save
      redirect_to @machine_condition, notice: 'Machine Condition was successfully created.'
    else
      render action: 'new'
    end
  end

  def destroy
    mcx = MachineCondition.find(params[:id])
    mcx.destroy

    render nothing: true
  end

  private
  def condition_params
    params.require(:machine_condition).permit(:comment, :location_machine_xref, :user, :user_id)
  end
end
