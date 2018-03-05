class OperatorsController < InheritedResources::Base
  respond_to :html, :xml, :json, :rss, only: %i[index show]
  has_scope :region

  def create
    @operator = Operator.new(operator_params)
    if @operator.save
      redirect_to @operator, notice: 'Operator was successfully created.'
    else
      render action: 'new'
    end
  end

  private

  def operator_params
    params.require(:operator).permit(:name, :region_id, :email, :website, :phone)
  end
end
