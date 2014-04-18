class API::V1::MachinesController < InheritedResources::Base
  respond_to :xml

  def index
    respond_with apply_scopes(Machine)
  end

end
