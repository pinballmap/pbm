require "rails_admin/application_controller"

module RailsAdmin
  class ApplicationController < ::ApplicationController
    filter_access_to :all
  end
end

RailsAdmin.config do |config|
  config.excluded_models << User << LocationMachineXref << MachineScoreXref

  config.model Region do
    list do
      field :motd
    end
  end
end

RailsAdmin::Adapters::ActiveRecord.module_eval do
  def all(options = {}, scope = nil)
    if (model.name == 'Region')
      model.all(merge_order(options)).select{|v| v.id == Authorization.current_user.region_id}
    elsif (model.column_names.include?('region_id'))
      model.all(merge_order(options)).select{|v| v.region_id == Authorization.current_user.region_id}
    elsif (model.name == 'Machine')
      if (Authorization.current_user.region_id != Region.find_by_name('portland').id)
        Array.new
      else
        model.all(merge_order(options))
      end
    else
      model.all(merge_order(options))
    end
  end
end
