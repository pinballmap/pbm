class API::V1::RegionsController < InheritedResources::Base
  respond_to :json

  def index
    respond_with(@regions = Region.all, :methods => [:subdir, :emailContact])
  end

  def location_names
    term = params[:term] || ''

    respond_with(Region.find(params[:id]).locations.map{|l| l.name}.grep(/#{params[:term]}/i).sort.map{|l| {:label => l, :value => l}})
  end

  def machine_names
    machines = params[:region_level_search].nil? ? Machine.all : Region.find(params[:id]).machines

    respond_with(machines.select{|m| m.name_and_year =~ /#{params[:term]}/i}.sort_by(&:name).map{|m| {:label => m.name_and_year, :value => m.name}})
  end

end
