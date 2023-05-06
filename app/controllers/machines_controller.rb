class MachinesController < InheritedResources::Base
  respond_to :xml, :json, only: %i[index show]

  def create
    @machine = Machine.new(machine_params)
    if @machine.save
      redirect_to @machine, notice: 'Machine was successfully created.'
    else
      render action: 'new'
    end
  end

  def autocomplete
    updated_at = Status.where(status_type: "machines").pluck("updated_at")[0]

    machines = Rails.cache.fetch("#{updated_at}/machines_for_autocomplete", expires_in: 12.hours) do
      Machine.all
    end

    render json: machines.select { |m| m.name_and_year =~ /#{Regexp.escape params[:term] || ''}/i }.sort_by(&:name).map { |m| { label: m.name_and_year, value: m.name_and_year, id: m.id } }
  end

  def index
    respond_with(@machines = Machine.by_name(params[:name]))
  end

  private

  def machine_params
    params.require(:machine).permit(:name, :ipdb_link, :year, :manufacturer, :machine_group_id, :ic_eligible)
  end
end
