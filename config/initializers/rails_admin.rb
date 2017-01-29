# RailsAdmin config file. Generated on April 08, 2012 09:44
# See github.com/sferik/rails_admin for more informations

RailsAdmin.config do |config|
  config.authorize_with :cancan

  config.current_user_method(&:current_user)

  config.audit_with :history, User

  config.main_app_name = ['Pinball Map', 'Admin']
  config.excluded_models = []

  config.model Event do
    list do
      field :name, :string
      field :location, :belongs_to_association
      field :external_location_name, :string
      field :start_date, :date
      field :end_date, :date
    end
    show do
      field :name, :string
      field :location, :belongs_to_association
      field :external_location_name, :string
      field :long_desc, :text
      field :external_link, :string
      field :category_no, :integer
      field :start_date, :date
      field :end_date, :date
      field :updated_at, :datetime
      field :category, :string
    end
    edit do
      field :name, :string
      field :location_id do
        render do
          bindings[:view].render :partial => 'location_select', :locals => {:object_type => 'event', :location_id => bindings[:object].location_id}
        end
      end
      field :external_location_name, :string
      field :long_desc, :text
      field :external_link, :string
      field :category_no, :integer
      field :start_date, :date
      field :end_date, :date
      field :category, :string
    end
    create do
      field :name, :string
      field :location_id do
        render do
          bindings[:view].render :partial => 'location_select', :locals => {:object_type => 'event', :location_id => nil}
        end
      end
      field :external_location_name, :string
      field :long_desc, :text
      field :external_link, :string
      field :category_no, :integer
      field :start_date, :date
      field :end_date, :date
      field :category, :string
      field :region_id do
        render do
          bindings[:view].render :partial => 'region_edit', :locals => {:region_id => Authorization.current_user.region_id, :object_type => 'event'}
        end
      end
    end
    export do; end
    update do; end
  end
  config.model Location do
    list do
      field :name, :string
      field :street, :string
      field :city, :string
      field :state, :string
      field :zip, :string
      field :phone, :string
      field :zone, :belongs_to_association
      field :operator, :belongs_to_association
    end
    show do
      field :name, :string
      field :zone, :belongs_to_association
      field :location_type, :belongs_to_association
      field :operator, :belongs_to_association
      field :street, :string
      field :city, :string
      field :state, :string
      field :zip, :string
      field :phone, :string
      field :lat, :decimal
      field :lon, :decimal
      field :website, :string
      field :updated_at, :datetime
      field :description, :string
    end
    edit do
      field :name, :string
      field :zone_id do
        render do
          bindings[:view].render :partial => 'zone_select', :locals => {:object_type => 'location', :zone_id => bindings[:object].zone_id}
        end
      end
      field :location_type_id do
        render do
          bindings[:view].render :partial => 'location_type_select', :locals => {:object_type => 'location', :location_type_id => bindings[:object].location_type_id}
        end
      end
      field :operator_id do
        render do
          bindings[:view].render :partial => 'operator_select', :locals => {:object_type => 'location', :operator_id => bindings[:object].operator_id}
        end
      end
      field :street, :string
      field :city, :string
      field :state, :string
      field :zip, :string
      field :phone, :string
      field :lat, :decimal
      field :lon, :decimal
      field :website, :string
      field :updated_at, :datetime
      field :description, :string
    end
    create do
      field :name, :string
      field :zone_id do
        render do
          bindings[:view].render :partial => 'zone_select', :locals => {:object_type => 'location', :zone_id => nil}
        end
      end
      field :location_type_id do
        render do
          bindings[:view].render :partial => 'location_type_select', :locals => {:object_type => 'location', :location_type_id => nil}
        end
      end
      field :operator_id do
        render do
          bindings[:view].render :partial => 'operator_select', :locals => {:object_type => 'location', :operator_id => bindings[:object].operator_id}
        end
      end
      field :street, :string
      field :city, :string
      field :state, :string
      field :zip, :string
      field :phone, :string
      field :lat, :decimal
      field :lon, :decimal
      field :website, :string
      field :description, :string
      field :region_id do
        render do
          bindings[:view].render :partial => 'region_edit', :locals => {:region_id => Authorization.current_user.is_super_admin ? nil : Authorization.current_user.region_id, :object_type => 'location'}
        end
      end
    end
    export do; end
    update do; end
  end
  config.model LocationPictureXref do
    list do
      field :location, :belongs_to_association
      field :created_at, :datetime
      field :description, :text
      field :approved, :boolean
    end
    show do
      field :location, :belongs_to_association
      field :created_at, :datetime
      field :description, :text
      field :photo, :paperclip
      field :approved, :boolean
    end
    edit do
      field :location, :belongs_to_association do
        read_only true
      end
      field :created_at, :datetime
      field :description, :text
      field :photo, :paperclip
      field :approved, :boolean
    end
    export do; end
    create do; end
    update do; end
  end
  config.model LocationType do
    list do
      field :name, :string
    end
    show do
      field :name, :string
    end
    edit do
      field :name, :string
    end
    export do; end
    create do; end
    update do; end
  end
  config.model Machine do
    list do
      field :name, :string
      field :manufacturer, :string
      field :year, :integer
      field :is_active, :boolean
      field :machine_group, :belongs_to_association
    end
    show do
      field :name, :string
      field :is_active, :boolean
      field :updated_at, :datetime
      field :machine_group, :belongs_to_association
    end
    edit do
      field :name, :string
      field :manufacturer, :string
      field :year, :integer
      field :ipdb_link, :string
      field :is_active, :boolean
      field :machine_group, :belongs_to_association
    end
    export do; end
    create do; end
    update do; end
  end
  config.model MachineGroup do
    list do
      field :name, :string
      field :updated_at, :datetime
    end
    show do
      field :name, :string
      field :updated_at, :datetime
    end
    edit do
      field :name, :string
      field :updated_at, :datetime
    end
    export do; end
    create do; end
    update do; end
  end
  config.model Operator do
    list do
      field :name, :string
      field :email, :string
      field :website, :string
      field :phone, :string
    end
    show do
      field :name, :string
      field :locations, :has_many_association
      field :email, :string
      field :website, :string
      field :phone, :string
      field :updated_at, :datetime
    end
    edit do
      field :name, :string
      field :email, :string
      field :website, :string
      field :phone, :string
    end
    create do
      field :name, :string
      field :email, :string
      field :website, :string
      field :phone, :string
      field :region_id do
        render do
          bindings[:view].render :partial => 'region_edit', :locals => {:region_id => Authorization.current_user.is_super_admin ? nil : Authorization.current_user.region_id, :object_type => 'operator'}
        end
      end
    end
    export do; end
    update do; end
  end
  config.model Region do
    list do
      field :name, :string
      field :full_name, :string
    end
    show do
      field :name, :string
      field :updated_at, :datetime
      field :full_name, :string
      field :motd, :string
      field :lat, :decimal
      field :lon, :decimal
      field :n_search_no, :integer
      field :default_search_type, :string
      field :should_email_machine_removal, :boolean
      field :should_auto_delete_empty_locations, :boolean
    end
    edit do
      field :updated_at, :datetime
      field :full_name, :string
      field :name do
        render do
          bindings[:view].render :partial => 'region_name_edit', :locals => {:region => bindings[:object]}
        end
      end
      field :motd, :string
      field :lat, :decimal
      field :lon, :decimal
      field :n_search_no, :integer
      field :default_search_type, :string
      field :should_email_machine_removal, :boolean
      field :should_auto_delete_empty_locations, :boolean
    end
    create do
      field :name, :string
      field :updated_at, :datetime
      field :full_name, :string
      field :motd, :string
      field :lat, :decimal
      field :lon, :decimal
      field :n_search_no, :integer
      field :default_search_type, :string
      field :should_email_machine_removal, :boolean
      field :should_auto_delete_empty_locations, :boolean
    end
    export do; end
    update do; end
  end
  config.model RegionLinkXref do
    list do
      field :name, :string
      field :url, :string
      field :description, :string
      field :category, :string
      field :sort_order, :integer
    end
    show do
      field :name, :string
      field :url, :string
      field :description, :string
      field :category, :string
      field :sort_order, :integer
    end
    edit do
      field :name, :string
      field :url, :string
      field :description, :string
      field :category, :string
      field :sort_order, :integer
    end
    create do
      field :name, :string
      field :url, :string
      field :description, :string
      field :category, :string
      field :sort_order, :integer
      field :region_id do
        render do
          bindings[:view].render :partial => 'region_edit', :locals => {:region_id => Authorization.current_user.region_id, :object_type => 'region_link_xref'}
        end
      end
    end
    export do; end
    update do; end
  end
  config.model User do
    list do
      field :email, :string
      field :username, :string
      field :region, :belongs_to_association
      field :is_disabled, :boolean
      field :last_sign_in_at, :datetime
    end
    show do
      field :email, :string
      field :username, :string
      field :region, :belongs_to_association
      field :is_disabled, :boolean
      field :last_sign_in_at, :datetime
    end
    edit do
      field :username, :string do
        visible do
          bindings[:view]._current_user.is_super_admin
        end
      end
      field :email, :string do
        visible do
          bindings[:view]._current_user.is_super_admin
        end
      end
      field :password, :password do
        visible do
          bindings[:view]._current_user.is_super_admin
        end
      end
      field :is_machine_admin, :boolean do
        visible do
          bindings[:view]._current_user.is_super_admin
        end
      end
      field :is_primary_email_contact, :boolean do
        visible do
          bindings[:view]._current_user.is_super_admin
        end
      end
      field :is_disabled, :boolean do
        visible do
          if bindings[:object].region_id
            bindings[:view]._current_user.is_super_admin
          else
            true
          end
        end
      end
      field :region_id do
        visible do
          bindings[:view]._current_user.is_super_admin
        end
        render do
          bindings[:view].render :partial => 'region_user', :locals => {:region_id => bindings[:object].region_id}
        end
      end
    end
    create do
      field :email, :string
      field :password, :password
      field :region_id do
        render do
          bindings[:view].render :partial => 'region_user', :locals => {:region_id => nil}
        end
      end
    end
    export do; end
    update do; end
  end
  config.model Zone do
    list do
      field :name, :string
      field :is_primary, :boolean
    end
    show do
      field :name, :string
      field :updated_at, :datetime
      field :is_primary, :boolean
    end
    edit do
      field :name, :string
      field :updated_at, :datetime
      field :is_primary, :boolean
    end
    create do
      field :name, :string
      field :is_primary, :boolean
      field :region_id do
        render do
          bindings[:view].render :partial => 'region_edit', :locals => {:region_id => Authorization.current_user.region_id, :object_type => 'zone'}
        end
      end
    end
    export do; end
    update do; end
  end
  config.model MachineScoreXref do
    list do
      field :location_machine_xref_id do
        label "Machine"
        pretty_value do
          bindings[:view].render :partial => 'show_location_and_machine', :locals => {:location_machine_xref_id => bindings[:object].location_machine_xref_id}
        end
        searchable [Location => :name]
      end
      field :score
    end
    show do
      field :location_machine_xref_id do
        label "Machine"
        pretty_value do
          bindings[:view].render :partial => 'show_location_and_machine', :locals => {:location_machine_xref_id => bindings[:object].location_machine_xref_id}
        end
      end
      field :score
    end
    edit do
      field :location_machine_xref_id do
        read_only true
        label "Machine"
        pretty_value do
          bindings[:view].render :partial => 'show_location_and_machine', :locals => {:location_machine_xref_id => bindings[:object].location_machine_xref_id}
        end
      end
      field :score
    end
    export do; end
    update do; end
  end
  config.model LocationMachineXref do
    edit do
      field :condition
    end
    list do
      field :updated_at
      field :condition
      field :location_id do
        label "Machine"
        pretty_value do
          bindings[:view].render :partial => 'show_location_and_machine', :locals => {:location_machine_xref_id => bindings[:object]}
        end
      end
    end
  end
  config.model UserSubmission do
    list do
      field :id, :integer
      field :submission_type, :string
      field :submission, :string
      field :region, :belongs_to_association
      field :user do
        searchable :username
      end
      field :user_email, :string
      field :created_at, :date
    end
    show do
      field :id, :integer
      field :submission_type, :string
      field :submission, :string
      field :region, :belongs_to_association
      field :user, :belongs_to_association
      field :user_email, :string
      field :created_at, :date
    end
    edit do; end
    create do; end
    export do; end
    update do; end
  end
end
