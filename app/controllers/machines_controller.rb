class MachinesController < InheritedResources::Base
  has_scope :by_name

  def autocomplete
    render :json => Machine.find(:all, :conditions => ['name like ?', '%' + params[:term] + '%']).map {|m| m.name}
  end

  def index
    @machines = apply_scopes(Machine).all

    render
  end
end
