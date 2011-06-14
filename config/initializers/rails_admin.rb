require "rails_admin/application_controller"

module RailsAdmin
  class ApplicationController < ::ApplicationController
    filter_access_to :all
  end
end

RailsAdmin.config do |config|
  config.list.default_items_per_page = 5000
  config.navigation.max_visible_tabs 15
  config.excluded_models << User << LocationMachineXref << MachineScoreXref

  config.model Location do
    list do
      sort_by :name
      sort_reverse false
    end
  end

  config.model Region do
    list do
      field :motd
    end
    create do
      group :default do
        hide
      end
    end
  end

  config.model LocationPictureXref do
    list do
      field :id
      field :approved
    end
    edit do
      field :approved
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
    elsif (model.name == 'LocationPictureXref')
      LocationPictureXref.all.select{|lpx| lpx.location.region_id == Authorization.current_user.region_id}
    else
      model.all(merge_order(options))
    end
  end
end
