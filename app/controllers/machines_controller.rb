class MachinesController < InheritedResources::Base
  respond_to :xml, :json, only: [:index, :show]
  has_scope :by_name

  def autocomplete
    machines = params[:region_level_search].nil? ? Machine.all : @region.machines

    render json: machines.select { |m| m.name_and_year =~ /#{Regexp.escape params[:term] || ''}/i }.sort_by(&:name).map { |m| { label: m.name_and_year, value: m.name_and_year, id: m.id } }
  end

  def index
    respond_with(@machines = apply_scopes(Machine).all)
  end
end
