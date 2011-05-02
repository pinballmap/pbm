class MachinesController < InheritedResources::Base
  respond_to :xml, :json, :only => [:index, :show]
  has_scope :by_name

  def autocomplete
    if (params['region_id'])
      render :json => Region.find(params['region_id']).machines.map{|m| m.name}.grep(/#{params[:term]}/)
    else
      render :json => Machine.find(:all, :conditions => ['upper(name) like upper(?)', '%' + params[:term] + '%']).map {|m| m.name}
    end
  end

  def index
    respond_with(@machines = apply_scopes(Machine).all)
  end
end
