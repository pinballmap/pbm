RailsAdmin.config do |config|
  config.asset_source = :sprockets
  config.authorize_with :cancancan

  config.authenticate_with do
    warden.authenticate! scope: :user
  end

  config.current_user_method(&:current_user)

  config.audit_with :paper_trail, 'User', 'PaperTrail::Version'

  config.actions do
    dashboard                     # mandatory
    index                         # mandatory
    new
    export
    bulk_delete
    show
    edit
    delete
    history_index do
      only ['Location', 'SuggestedLocation', 'Operator', 'RegionLinkXref', 'Zone', 'Region', 'BannedIp', 'Machine', 'LocationType', 'MachineCondition']
    end
    history_show do
      only ['Location', 'SuggestedLocation', 'Operator', 'RegionLinkXref', 'Zone', 'Region', 'BannedIp', 'Machine', 'LocationType', 'MachineCondition']
    end
  end

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
          bindings[:view].render :partial => 'region_edit', :locals => {:region_id => bindings[:view]._current_user.region_id, :object_type => 'event'}
        end
      end
    end
    export do; end
    update do; end
  end
  config.model Location do
    list do
      scopes [nil, :zoneless]
      field :name, :string
      field :region, :belongs_to_association do
        visible do
          bindings[:view]._current_user.is_super_admin
        end
      end
      field :street, :string
      field :city, :string
      field :state, :string
      field :zip, :string
      field :country, :string
      field :phone, :string
      field :zone, :belongs_to_association
      field :operator, :belongs_to_association
      field :location_type, :belongs_to_association
      field :website, :string
      field :description, :string
      field :is_stern_army, :boolean do
        visible do
          bindings[:view]._current_user.is_super_admin
        end
      end
    end
    show do
      field :name, :string
      field :region, :belongs_to_association do
        visible do
          bindings[:view]._current_user.is_super_admin
        end
      end
      field :zone, :belongs_to_association
      field :location_type, :belongs_to_association
      field :operator, :belongs_to_association
      field :street, :string
      field :city, :string
      field :state, :string
      field :zip, :string
      field :country, :string
      field :phone, :string
      field :lat, :decimal
      field :lon, :decimal
      field :website, :string
      field :updated_at, :datetime
      field :description do
        html_attributes rows: 5, cols: 50
      end
      field :is_stern_army, :boolean do
        visible do
          bindings[:view]._current_user.is_super_admin
        end
      end
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
      field :country do
        render do
          bindings[:view].render :partial => 'country_select', :locals => {:object_type => 'location', :country => bindings[:object].country}
        end
      end
      field :phone, :string
      field :lat, :decimal do
        required false
      end
      field :lon, :decimal do
        required false
      end
      field :website, :string
      field :description do
        html_attributes rows: 5, cols: 50
      end
      field :region_id do
        render do
          bindings[:view].render :partial => 'region_edit', :locals => {:region_id => bindings[:view]._current_user.is_super_admin ? bindings[:object].region_id : bindings[:view]._current_user.region_id, :object_type => 'location'}
        end
      end
      field :is_stern_army, :boolean do
        visible do
          bindings[:view]._current_user.is_super_admin
        end
      end
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
      field :country do
        render do
          bindings[:view].render :partial => 'country_select', :locals => {:object_type => 'location', :country => bindings[:object].country}
        end
      end
      field :phone, :string
      field :lat, :decimal do
        required false
      end
      field :lon, :decimal do
        required false
      end
      field :website, :string
      field :description do
        html_attributes rows: 5, cols: 50
      end
      field :region_id do
        render do
          bindings[:view].render :partial => 'region_edit', :locals => {:region_id => bindings[:view]._current_user.region_id, :object_type => 'location'}
        end
      end
      field :location_machine_xrefs do
        visible false
      end
      field :machines do
        orderable true
      end
      field :is_stern_army, :boolean do
        visible do
          bindings[:view]._current_user.is_super_admin
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
    end
    show do
      field :location, :belongs_to_association
      field :created_at, :datetime
      field :description, :text
      field :photo do
        pretty_value do
          bindings[:view].image_tag bindings[:object].photo.variant(resize_to_limit: [800,800])
        end
      end
    end
    edit do
      field :location, :belongs_to_association do
        read_only true
      end
      field :created_at, :datetime
      field :description, :text
      field :photo do
        pretty_value do
          bindings[:view].image_tag bindings[:object].photo.variant(resize_to_limit: [800,800])
        end
      end
    end
    export do; end
    create do; end
    update do; end
  end
  config.model LocationType do
    list do
      field :name, :string
      field :icon, :string
      field :library, :string
    end
    show do
      field :name, :string
      field :icon, :string
      field :library, :string
    end
    edit do
      field :name, :string
      field :icon, :string
      field :library, :string
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
      field :kineticist_url, :string
      field :ipdb_link, :string
      field :ipdb_id, :integer
      field :opdb_id, :string
      field :opdb_img, :string
      field :opdb_img_height, :integer
      field :opdb_img_width, :integer
      field :machine_type, :string
      field :machine_display, :string
      field :ic_eligible, :boolean
      field :machine_group, :belongs_to_association
    end
    show do
      field :name, :string
      field :is_active, :boolean
      field :updated_at, :datetime
      field :kineticist_url, :string
      field :ipdb_link, :string
      field :ipdb_id, :integer
      field :opdb_id, :string
      field :opdb_img, :string
      field :opdb_img_height, :integer
      field :opdb_img_width, :integer
      field :machine_type, :string
      field :machine_display, :string
      field :ic_eligible, :boolean
      field :machine_group, :belongs_to_association
    end
    edit do
      field :name, :string
      field :manufacturer, :string
      field :year, :integer
      field :kineticist_url, :string
      field :ipdb_link, :string
      field :ipdb_id, :integer
      field :opdb_id, :string
      field :opdb_img, :string
      field :opdb_img_height, :integer
      field :opdb_img_width, :integer
      field :machine_type, :string
      field :machine_display, :string
      field :ic_eligible, :boolean
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
      field :region_id do
        render do
          bindings[:view].render :partial => 'region_edit', :locals => {:region_id => bindings[:view]._current_user.is_super_admin ? bindings[:object].region_id : bindings[:view]._current_user.region_id, :object_type => 'operator'}
        end
      end
    end
    create do
      field :name, :string
      field :email, :string
      field :website, :string
      field :phone, :string
      field :region_id do
        render do
          bindings[:view].render :partial => 'region_edit', :locals => {:region_id => bindings[:view]._current_user.is_super_admin ? bindings[:object].region_id : bindings[:view]._current_user.region_id, :object_type => 'operator'}
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
      field :state, :string
      field :motd, :string
      field :lat, :decimal
      field :lon, :decimal
      field :effective_radius, :decimal
      field :n_search_no, :integer
      field :default_search_type, :string
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
      field :state, :string
      field :lat, :decimal
      field :lon, :decimal
      field :effective_radius, :decimal
      field :n_search_no, :integer
      field :default_search_type, :string
      field :should_auto_delete_empty_locations, :boolean
    end
    create do
      field :name, :string
      field :updated_at, :datetime
      field :full_name, :string
      field :state, :string
      field :motd, :string
      field :lat, :decimal
      field :lon, :decimal
      field :effective_radius, :decimal
      field :n_search_no, :integer
      field :default_search_type, :string
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
          bindings[:view].render :partial => 'region_edit', :locals => {:region_id => bindings[:view]._current_user.region_id, :object_type => 'region_link_xref'}
        end
      end
    end
    export do; end
    update do; end
  end
  config.model User do
    list do
      scopes [nil, :admins, :non_admins]
      field :email, :string
      field :username, :string
      field :region, :belongs_to_association
      field :created_at, :datetime
      field :confirmed_at, :datetime
      field :is_disabled, :boolean
      field :notes, :string
    end
    show do
      field :email, :string
      field :username, :string
      field :region, :belongs_to_association
      field :created_at, :datetime
      field :confirmed_at, :datetime
      field :is_disabled, :boolean
      field :notes, :string
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
      field :notes, :string do
        visible do
          bindings[:view]._current_user.is_super_admin
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
          bindings[:view].render :partial => 'region_edit', :locals => {:region_id => bindings[:view]._current_user.region_id, :object_type => 'zone'}
        end
      end
    end
    export do; end
    update do; end
  end
  config.model MachineScoreXref do
    list do
      field :score
      field :machine do
        eager_load true
        searchable [:name]
      end
      field :location do
        eager_load true
        searchable [:name]
      end
      field :user do
        searchable :username
      end
    end
    show do
      field :score
      field :machine do
        eager_load true
        searchable [:name]
      end
      field :location do
        eager_load true
        searchable [:name]
      end
      field :user do
        searchable :username
      end
    end
    edit do
      field :score
    end
    export do; end
    update do; end
  end
  config.model MachineCondition do
    list do
      field :id, :integer
      field :comment
      field :user do
        searchable :username
      end
      field :machine do
        eager_load true
        searchable [:name]
      end
      field :location do
        eager_load true
        searchable [:name]
      end
      field :created_at, :date
      field :updated_at, :date
    end
    show do
      field :id, :integer
      field :comment
      field :user do
        searchable :username
      end
      field :machine do
        eager_load true
        searchable [:name]
      end
      field :location do
        eager_load true
        searchable [:name]
      end
      field :created_at, :date
      field :updated_at, :date
    end
    edit do
      field :comment
      field :user do
        read_only true
      end
      field :machine
      field :location
    end
    create do; end
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
    end
  end
  config.model UserSubmission do
    list do
      field :id, :integer
      field :submission_type, :string
      field :submission, :string
      field :region, :belongs_to_association
      field :location, :belongs_to_association
      field :user do
        searchable :username
      end
      field :user_email, :string
      field :created_at, :date
      field :deleted_at, :datetime
    end
    show do
      field :id, :integer
      field :submission_type, :string
      field :submission, :string
      field :region, :belongs_to_association
      field :location, :belongs_to_association
      field :city_name, :string
      field :machine_name, :string
      field :user, :belongs_to_association
      field :user_email, :string
      field :high_score, :integer
      field :machine_score_xref_id, :integer
      field :comment, :string
      field :machine_condition_id, :integer
      field :created_at do
        date_format :long
      end
      field :deleted_at, :datetime
    end
    edit do
      field :submission_type, :string
      field :submission, :string
      field :region, :belongs_to_association
      field :user, :belongs_to_association
      field :location, :belongs_to_association
      field :machine_name, :string
      field :comment, :string
      field :user_name, :string
      field :high_score, :integer
      field :deleted_at, :datetime
    end
    create do; end
    export do; end
    update do; end
  end
  config.model SuggestedLocation do
    list do
      field :name, :string
      field :region, :belongs_to_association do
        visible do
          bindings[:view]._current_user.is_super_admin
        end
      end
      field :street, :string
      field :city, :string
      field :state, :string
      field :zip, :string
      field :country, :string
      field :phone, :string
      field :website, :string
      field :operator, :belongs_to_association
      field :zone, :belongs_to_association
      field :created_at, :datetime
    end
    edit do
      field :name, :string
      field :region_id do
        render do
          bindings[:view].render :partial => 'region_edit', :locals => {:region_id => bindings[:object].region_id, :object_type => 'suggested_location'}
        end
      end
      field :location_type_id do
        render do
          bindings[:view].render :partial => 'location_type_select', :locals => {:object_type => 'suggested_location', :location_type_id => bindings[:object].location_type_id}
        end
      end
      field :operator_id do
        render do
          bindings[:view].render :partial => 'operator_select', :locals => {:object_type => 'suggested_location', :operator_id => bindings[:object].operator_id}
        end
      end
      field :zone_id do
        render do
          bindings[:view].render :partial => 'zone_select', :locals => {:object_type => 'suggested_location', :zone_id => bindings[:object].zone_id}
        end
      end
      field :street, :string
      field :city, :string
      field :state, :string
      field :zip, :string
      field :country do
        render do
          bindings[:view].render :partial => 'country_select', :locals => {:object_type => 'suggested_location', :country => bindings[:object].country}
        end
      end
      field :phone, :string
      field :lat, :decimal do
        required false
      end
      field :lon, :decimal do
        required false
      end
      field :website, :string
      field :comments do
        html_attributes rows: 5, cols: 50
      end
    end
    show do
      field :full_street_address, :string do
        label "APPROVE LOCATION"
        pretty_value do
          bindings[:view].render partial: 'convert_suggested_location_to_location', locals: {suggested_location: bindings[:object]}
        end
      end
      field :name, :string
      field :location_type, :belongs_to_association
      field :operator, :belongs_to_association
      field :zone, :belongs_to_association
      field :region, :belongs_to_association
      field :street, :string
      field :city, :string
      field :state, :string
      field :zip, :string
      field :country, :string
      field :phone, :string
      field :lat, :decimal
      field :lon, :decimal
      field :website, :string
      field :comments do
        html_attributes rows: 5, cols: 50
      end
      field :user_inputted_address, :string
      field :machines, :string
      field :created_at, :datetime
      field :updated_at, :datetime
    end
  end
end
