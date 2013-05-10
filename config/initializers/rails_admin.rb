# RailsAdmin config file. Generated on April 08, 2012 09:44
# See github.com/sferik/rails_admin for more informations

RailsAdmin.config do |config|
  config.authorize_with :cancan

  # If your default_local is different from :en, uncomment the following 2 lines and set your default locale here:
  # require 'i18n'
  # I18n.default_locale = :de

  config.current_user_method { current_user } # auto-generated

  # If you want to track changes on your models:
  config.audit_with :history, User

  # Or with a PaperTrail: (you need to install it first)
  # config.audit_with :paper_trail, User

  # Set the admin name here (optional second array element will appear in a beautiful RailsAdmin red ©)
  config.main_app_name = ['Pinball Map', 'Admin']
  # or for a dynamic name:
  # config.main_app_name = Proc.new { |controller| [Rails.application.engine_name.titleize, controller.params['action'].titleize] }


  #  ==> Global show view settings
  # Display empty fields in show views
  # config.compact_show_view = false

  #  ==> Global list view settings
  # Number of default rows per-page:
  # config.default_items_per_page = 20

  #  ==> Included models
  # Add all excluded models here:
  config.excluded_models = []

  # Add models here if you want to go 'whitelist mode':
  # config.included_models = [Event, Location, LocationMachineXref, LocationPictureXref, LocationType, Machine, Operator, Region, RegionLinkXref, Zone]

  # Application wide tried label methods for models' instances
  # config.label_methods << :description # Default is [:name, :title]

  #  ==> Global models configuration
  # config.models do
  #   # Configuration here will affect all included models in all scopes, handle with care!
  #
  #   list do
  #     # Configuration here will affect all included models in list sections (same for show, export, edit, update, create)
  #
  #     fields_of_type :date do
  #       # Configuration here will affect all date fields, in the list section, for all included models. See README for a comprehensive type list.
  #     end
  #   end
  # end
  #
  #  ==> Model specific configuration
  # Keep in mind that *all* configuration blocks are optional.
  # RailsAdmin will try his best to provide the best defaults for each section, for each field.
  # Try to override as few things as possible, in the most generic way. Try to avoid setting labels for models and attributes, use ActiveRecord I18n API instead.
  # Less code is better code!
  # config.model MyModel do
  #   # Cross-section field configuration
  #   object_label_method :name     # Name of the method called for pretty printing an *instance* of ModelName
  #   label 'My model'              # Name of ModelName (smartly defaults to ActiveRecord's I18n API)
  #   label_plural 'My models'      # Same, plural
  #   weight -1                     # Navigation priority. Bigger is higher.
  #   parent OtherModel             # Set parent model for navigation. MyModel will be nested below. OtherModel will be on first position of the dropdown
  #   navigation_label              # Sets dropdown entry's name in navigation. Only for parents!
  #   # Section specific configuration:
  #   list do
  #     filters [:id, :name]  # Array of field names which filters should be shown by default in the table header
  #     items_per_page 100    # Override default_items_per_page
  #     sort_by :id           # Sort column (default is primary key)
  #     sort_reverse true     # Sort direction (default is true for primary key, last created first)
  #     # Here goes the fields configuration for the list view
  #   end
  # end

  # Your model's configuration, to help you get started:

  # All fields marked as 'hidden' won't be shown anywhere in the rails_admin unless you mark them as visible. (visible(true))

  config.model Event do
    list do
      field :name, :string 
      field :location, :belongs_to_association
      field :start_date, :date 
      field :end_date, :date 
    end
    show do
      field :name, :string 
      field :location, :belongs_to_association
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
    create do
      field :name, :string 
      field :zone_id do
        render do
          bindings[:view].render :partial => 'zone_select', :locals => {:object_type => 'location', :zone_id => nil}
        end
      end
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
      field :description, :string 
      field :region_id do
        render do
          bindings[:view].render :partial => 'region_edit', :locals => {:region_id => Authorization.current_user.region_id, :object_type => 'location'}
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
    end
    show do
      field :name, :string
      field :is_active, :boolean
      field :updated_at, :datetime
    end
    edit do
      field :name, :string
      field :manufacturer, :string
      field :year, :integer
      field :ipdb_link, :string
      field :is_active, :boolean
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
          bindings[:view].render :partial => 'region_edit', :locals => {:region_id => Authorization.current_user.region_id, :object_type => 'operator'}
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
      field :lat, :float 
      field :lon, :float 
      field :n_search_no, :integer 
      field :default_search_type, :string 
      field :should_email_machine_removal, :boolean
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
      field :lat, :float 
      field :lon, :float 
      field :n_search_no, :integer 
      field :default_search_type, :string 
      field :should_email_machine_removal, :boolean
    end
    create do
      field :name, :string 
      field :updated_at, :datetime 
      field :full_name, :string 
      field :motd, :string 
      field :lat, :float 
      field :lon, :float 
      field :n_search_no, :integer 
      field :default_search_type, :string 
      field :should_email_machine_removal, :boolean
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
      field :region, :belongs_to_association
      field :last_sign_in_at, :datetime
    end
    show do
      field :email, :string 
      field :region, :belongs_to_association
      field :last_sign_in_at, :datetime
    end
    edit do
      field :email, :string 
      field :is_machine_admin, :boolean 
      field :is_primary_email_contact, :boolean 
      field :email, :string 
      field :region_id do
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
      end
      field :rank
      field :score
    end
    show do
      field :location_machine_xref_id do
        label "Machine"
        pretty_value do
          bindings[:view].render :partial => 'show_location_and_machine', :locals => {:location_machine_xref_id => bindings[:object].location_machine_xref_id}
        end
      end
      field :rank
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
      field :rank
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
end
