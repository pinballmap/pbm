class MachinesController < InheritedResources::Base
  respond_to :xml, :json, :only => [:index, :show]
  has_scope :by_name

  def autocomplete
    render :json => Machine.find(:all, :conditions => ['upper(name) like upper(?)', '%' + params[:term] + '%']).map {|m| m.name}
  end

  def index
    respond_with(@machines = apply_scopes(Machine).all)
  end
end
