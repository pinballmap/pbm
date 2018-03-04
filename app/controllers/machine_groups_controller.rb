class MachineGroupsController < InheritedResources::Base
  respond_to :html, :xml, :json, :rss, only: %i[index show]
  has_scope :region

  def create
    @machine_group = MachineGroup.new(machine_group_params)
    if @machine_group.save
      redirect_to @machine_group, notice: 'MachineGroup was successfully created.'
    else
      render action: 'new'
    end
  end

  private
  def machine_group_params
    params.require(:machine_group).permit(:name)
  end
end
