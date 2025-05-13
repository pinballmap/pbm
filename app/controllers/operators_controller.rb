class OperatorsController < ApplicationController
  has_scope :region

  def autocomplete
    operators = Operator.all

    render json: operators.select { |o| o.name =~ /#{Regexp.escape params[:term] || ''}/i }.sort_by(&:name).map { |o| { label: o.name, value: o.name, id: o.id } }
  end
end
