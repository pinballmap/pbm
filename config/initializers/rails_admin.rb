module RailsAdmin
  module Extensions
    module CanCanCan2
      class AuthorizationAdapter < RailsAdmin::Extensions::CanCanCan::AuthorizationAdapter
        def authorize(action, abstract_model = nil, model_object = nil)
          return unless action
          reaction, subject = fetch_action_and_subject(action, abstract_model, model_object)
          @controller.current_ability.authorize!(reaction, subject)
        end

        def authorized?(action, abstract_model = nil, model_object = nil)
          return unless action
          reaction, subject = fetch_action_and_subject(action, abstract_model, model_object)
          @controller.current_ability.can?(reaction, subject)
        end

        def fetch_action_and_subject(action, abstract_model, model_object)
          reaction = action
          subject = model_object || abstract_model&.model
          unless subject
            subject = reaction
            reaction = :read
          end
          return reaction, subject
        end
      end
    end
  end
end

RailsAdmin.add_extension(:cancancan2, RailsAdmin::Extensions::CanCanCan2, authorization: true)

RailsAdmin.config do |config|
  config.authorize_with :cancancan2

  config.authenticate_with do
    warden.authenticate! scope: :user
  end

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
      field :description, :string
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
      field :updated_at, :datetime
      field :description, :string
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
      field :description, :string
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
          bindings[:view].tag(:img, src: bindings[:object].photo.url(:large))
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
          bindings[:view].tag(:img, src: bindings[:object].photo.url(:large))
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
      field :ipdb_link, :string
      field :ipdb_id, :integer
      field :opdb_id, :string
      field :opdb_img, :string
      field :opdb_img_height, :integer
      field :opdb_img_width, :integer
      field :machine_group, :belongs_to_association
    end
    show do
      field :name, :string
      field :is_active, :boolean
      field :updated_at, :datetime
      field :ipdb_link, :string
      field :ipdb_id, :integer
      field :opdb_id, :string
      field :opdb_img, :string
      field :opdb_img_height, :integer
      field :opdb_img_width, :integer
      field :machine_group, :belongs_to_association
    end
    edit do
      field :name, :string
      field :manufacturer, :string
      field :year, :integer
      field :ipdb_link, :string
      field :ipdb_id, :integer
      field :opdb_id, :string
      field :opdb_img, :string
      field :opdb_img_height, :integer
      field :opdb_img_width, :integer
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
      field :should_email_machine_removal, :boolean
      field :should_auto_delete_empty_locations, :boolean
      field :send_digest_comment_emails, :boolean
      field :send_digest_removal_emails, :boolean
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
      field :should_email_machine_removal, :boolean
      field :should_auto_delete_empty_locations, :boolean
      field :send_digest_comment_emails, :boolean
      field :send_digest_removal_emails, :boolean
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
      field :should_email_machine_removal, :boolean
      field :should_auto_delete_empty_locations, :boolean
      field :send_digest_comment_emails, :boolean
      field :send_digest_removal_emails, :boolean
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
          bindings[:view].render :partial => 'region_edit', :locals => {:region_id => bindings[:view]._current_user.region_id, :object_type => 'zone'}
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
  config.model MachineCondition do
    list do
      field :id, :integer
      field :comment
      field :user do
        searchable :username
      end
      field :machine, :belongs_to_association
      field :location, :belongs_to_association
      field :created_at, :date
      field :updated_at, :date
    end
    show do
      field :id, :integer
      field :comment
      field :user do
        searchable :username
      end
      field :machine, :belongs_to_association
      field :location, :belongs_to_association
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
      field :location, :belongs_to_association
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
      field :location, :belongs_to_association
      field :user, :belongs_to_association
      field :user_email, :string
      field :created_at do
        date_format :long
      end
    end
    edit do; end
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
      field :operator, :belongs_to_association
      field :zone, :belongs_to_association
      field :created_at, :datetime
      field :updated_at, :datetime
    end
    edit do
      field :name, :string
      field :region_id do
        render do
          bindings[:view].render :partial => 'region_edit', :locals => {:region_id => bindings[:view]._current_user.is_super_admin ? bindings[:object].region_id : bindings[:view]._current_user.region_id, :object_type => 'suggested_location'}
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
      field :comments, :string
      field :user_inputted_address, :string
      field :machines, :string
      field :created_at, :datetime
      field :updated_at, :datetime
    end
  end
end
