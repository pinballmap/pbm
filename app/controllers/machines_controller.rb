class MachinesController < InheritedResources::Base
  has_scope :by_name

  protected
    def collection
      @machines ||= end_of_association_chain.paginate(:page => params[:page])
    end
end
