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

  editable_location_fields = [
      'name',
      'street',
      'city',
      'state',
      'zip',
      'phone',
      'lat',
      'lon',
      'description',
      'website',
      'operator_id',
      'zone_id',
      'location_type_id',
  ]
  config.model Location do
    list do
      sort_by :name
      sort_reverse false
    end

    create do
      editable_location_fields.each do |location_field|
        field location_field.to_sym
      end
      field :region_id do
        render do
          bindings[:view].render :partial => 'region_edit', :locals => {:region_id => Authorization.current_user.region_id, :object_type => 'location'}
        end
      end
    end
    edit do
      editable_location_fields.each do |location_field|
        field location_field.to_sym
      end
      field :region_id do
        render do
          bindings[:view].render :partial => 'region_edit', :locals => {:region_id => Authorization.current_user.region_id, :object_type => 'location'}
        end
      end
    end
  end

  editable_event_fields = [
    'name',
    'long_desc',
    'external_link',
    'category_no',
    'start_date',
    'end_date',
    'location_id',
    'category',
  ]
  config.model Event do
    edit do
      editable_event_fields.each do |event_field|
        field event_field.to_sym
      end
      field :region_id do
        render do
          bindings[:view].render :partial => 'region_edit', :locals => {:region_id => Authorization.current_user.region_id, :object_type => 'event'}
        end
      end
    end
    create do
      editable_event_fields.each do |event_field|
        field event_field.to_sym
      end
      field :region_id do
        render do
          bindings[:view].render :partial => 'region_edit', :locals => {:region_id => Authorization.current_user.region_id, :object_type => 'event'}
        end
      end
    end
  end

  editable_operator_fields = [
    'name',
    'email',
    'website',
    'phone',
  ]
  config.model Operator do
    edit do
      editable_operator_fields.each do |operator_field|
        field operator_field.to_sym
      end
      field :region_id do
        render do
          bindings[:view].render :partial => 'region_edit', :locals => {:region_id => Authorization.current_user.region_id, :object_type => 'operator'}
        end
      end
    end
    create do
      editable_operator_fields.each do |operator_field|
        field operator_field.to_sym
      end
      field :region_id do
        render do
          bindings[:view].render :partial => 'region_edit', :locals => {:region_id => Authorization.current_user.region_id, :object_type => 'operator'}
        end
      end
    end
  end

  editable_region_fields = [
    'motd',
    'full_name',
    'lat',
    'lon',
    'n_search_no',
  ]
  config.model Region do
    edit do
      editable_region_fields.each do |region_field|
        field region_field.to_sym
      end
    end
    create do
      group :default do
        hide
      end
    end
  end

  editable_region_link_xref_fields = [
    'name',
    'url',
    'description',
    'category',
    'sort_order',
  ]
  config.model RegionLinkXref do
    edit do
      editable_region_link_xref_fields.each do |region_link_xref_field|
        field region_link_xref_field.to_sym
      end
      field :region_id do
        render do
          bindings[:view].render :partial => 'region_edit', :locals => {:region_id => Authorization.current_user.region_id, :object_type => 'region_link_xref'}
        end
      end
    end
    create do
      editable_region_link_xref_fields.each do |region_link_xref_field|
        field region_link_xref_field.to_sym
      end
      field :region_id do
        render do
          bindings[:view].render :partial => 'region_edit', :locals => {:region_id => Authorization.current_user.region_id, :object_type => 'region_link_xref'}
        end
      end
    end
  end

  editable_zone_fields = [
    'name',
    'short_name',
    'is_primary',
  ]
  config.model Zone do
    edit do
      editable_zone_fields.each do |zone_field|
        field zone_field.to_sym
      end
      field :region_id do
        render do
          bindings[:view].render :partial => 'region_edit', :locals => {:region_id => Authorization.current_user.region_id, :object_type => 'zone'}
        end
      end
    end
    create do
      editable_zone_fields.each do |zone_field|
        field zone_field.to_sym
      end
      field :region_id do
        render do
          bindings[:view].render :partial => 'region_edit', :locals => {:region_id => Authorization.current_user.region_id, :object_type => 'zone'}
        end
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
