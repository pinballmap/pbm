class MachinesController < InheritedResources::Base
  respond_to :xml, :json, :only => [:index, :show]
  has_scope :by_name

  def autocomplete
    machines = params[:region_level_search].nil? ? Machine.all : @region.machines

    render :json => machines.select{|m| m.name_and_year =~ /#{params[:term]}/i}.sort_by(&:name).map{|m| {:label => m.name_and_year, :value => m.name}}
  end

  def index
    respond_with(@machines = apply_scopes(Machine).all)
  end
end
