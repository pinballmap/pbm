class OperatorsController < InheritedResources::Base
  respond_to :html, :xml, :json, :rss, only: %i[index show]
  has_scope :region

  def create
    @operator = Operator.new(operator_params)
    if @operator.save
      redirect_to @operator, notice: "Operator was successfully created."
    else
      render action: "new"
    end
  end

  def autocomplete
    operators = Operator.all

    render json: operators.select { |o| o.name =~ /#{Regexp.escape params[:term] || ''}/i }.sort_by(&:name).map { |o| { label: o.name, value: o.name, id: o.id } }
  end

  private

  def operator_params
    params.require(:operator).permit(:name, :region_id, :email, :website, :phone)
  end
end
