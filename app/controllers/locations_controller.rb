class LocationsController < InheritedResources::Base
  has_scope :by_name

  protected
    def collection
      @locations ||= end_of_association_chain.paginate(:page => params[:page])
    end
end
