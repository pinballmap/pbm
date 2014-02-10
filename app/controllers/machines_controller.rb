class MachinesController < InheritedResources::Base
  respond_to :xml, :json, :only => [:index, :show]
  has_scope :by_name

  def index
    respond_with(@machines = apply_scopes(Machine).all)
  end
end
