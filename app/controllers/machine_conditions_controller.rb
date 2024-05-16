class MachineConditionsController < InheritedResources::Base
  respond_to :xml, :json, :html, :js, :rss
  before_action :authenticate_user!, except: %i[index show]

  def create
    @machine_condition = MachineCondition.new(machine_condition_params)
    if @machine_condition.save
      redirect_to @machine_condition, notice: 'Machine Condition was successfully created.'
    else
      render action: 'new'
    end
  end

  def destroy
    user = current_user.nil? ? nil : current_user
    mcx = MachineCondition.find(params[:id])

    mcx.destroy if user && (user.id == mcx.user_id)

    render nothing: true
  end

  def update
    user = current_user.nil? ? nil : current_user
    mcx = MachineCondition.find(params[:id])

    mcx.update(condition_params) if user && (user.id == mcx.user_id)

    render nothing: true
  end

  private

  def condition_params
    params.permit(:comment)
  end
end
