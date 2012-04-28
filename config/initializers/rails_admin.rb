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
  config.main_app_name = ['Pbm', 'Admin']
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
  config.excluded_models = [Region, User]

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
    # Found associations:
      configure :location, :belongs_to_association   #   # Found columns:
      configure :name, :string 
      configure :long_desc, :text 
      configure :external_link, :string 
      configure :category_no, :integer 
      configure :start_date, :date 
      configure :end_date, :date 
      configure :created_at, :datetime 
      configure :updated_at, :datetime 
      configure :category, :string   #   # Sections:
    list do; end
    export do; end
    show do; end
    edit do; end
    create do; end
    update do; end
  end
  config.model Location do
    # Found associations:
      configure :zone, :belongs_to_association 
      configure :location_type, :belongs_to_association 
      configure :operator, :belongs_to_association 
      configure :events, :has_many_association 
      configure :machines, :has_many_association 
      configure :location_machine_xrefs, :has_many_association 
      configure :location_picture_xrefs, :has_many_association   #   # Found columns:
      configure :name, :string 
      configure :street, :string 
      configure :city, :string 
      configure :state, :string 
      configure :zip, :string 
      configure :phone, :string 
      configure :lat, :decimal 
      configure :lon, :decimal 
      configure :website, :string 
      configure :created_at, :datetime 
      configure :updated_at, :datetime 
      configure :description, :string 
    list do; end
    export do; end
    show do; end
    edit do; end
    create do; end
    update do; end
  end
  config.model LocationMachineXref do
    # Found associations:
      configure :location, :belongs_to_association 
      configure :machine, :belongs_to_association 
      configure :user, :belongs_to_association         # Hidden 
      configure :machine_score_xrefs, :has_many_association         # Hidden   #   # Found columns:
      configure :id, :integer 
      configure :created_at, :datetime 
      configure :updated_at, :datetime 
      configure :location_id, :integer         # Hidden 
      configure :machine_id, :integer         # Hidden 
      configure :condition, :text 
      configure :condition_date, :date 
      configure :ip, :string 
      configure :user_id, :integer         # Hidden 
      configure :machine_score_xrefs_count, :integer   #   # Sections:
    list do; end
    export do; end
    show do; end
    edit do; end
    create do; end
    update do; end
  end
  config.model LocationPictureXref do
    # Found associations:
      configure :location, :belongs_to_association 
      configure :user, :belongs_to_association         # Hidden   #   # Found columns:
      configure :id, :integer 
      configure :location_id, :integer         # Hidden 
      configure :created_at, :datetime 
      configure :updated_at, :datetime 
      configure :photo, :carrierwave 
      configure :description, :text 
      configure :approved, :boolean 
      configure :user_id, :integer         # Hidden   #   # Sections:
    list do; end
    export do; end
    show do; end
    edit do; end
    create do; end
    update do; end
  end
  config.model LocationType do
    # Found associations:
      configure :locations, :has_many_association   #   # Found columns:
      configure :id, :integer 
      configure :created_at, :datetime 
      configure :updated_at, :datetime 
      configure :name, :string   #   # Sections:
    list do; end
    export do; end
    show do; end
    edit do; end
    create do; end
    update do; end
  end
  config.model Machine do
    # Found associations:
    # Found columns:
    configure :id, :integer 
    configure :name, :string 
    configure :is_active, :boolean 
    configure :created_at, :datetime 
    configure :updated_at, :datetime   #   # Sections:
    list do; end
    export do; end
    show do; end
    edit do; end
    create do; end
    update do; end
  end
  config.model Operator do
    # Found associations:
      configure :locations, :has_many_association   #   # Found columns:
      configure :name, :string 
      configure :email, :string 
      configure :website, :string 
      configure :phone, :string 
      configure :created_at, :datetime 
      configure :updated_at, :datetime   #   # Sections:
    list do; end
    export do; end
    show do; end
    edit do; end
    create do; end
    update do; end
  end
  config.model Region do
    # Found associations:
    configure :locations, :has_many_association 
    configure :zones, :has_many_association 
    configure :users, :has_many_association         # Hidden 
    configure :events, :has_many_association 
    configure :operators, :has_many_association 
    configure :region_link_xrefs, :has_many_association 
    configure :location_machine_xrefs, :has_many_association   #   # Found columns:
    configure :id, :integer 
    configure :name, :string 
    configure :created_at, :datetime 
    configure :updated_at, :datetime 
    configure :full_name, :string 
    configure :motd, :string 
    configure :lat, :float 
    configure :lon, :float 
    configure :n_search_no, :integer 
    configure :default_search_type, :string 
    configure :should_email_machine_removal, :boolean   #   # Sections:
    list do; end
    export do; end
    show do; end
    edit do; end
    create do; end
    update do; end
  end
  config.model RegionLinkXref do
    # Found associations:
      configure :id, :integer 
      configure :name, :string 
      configure :url, :string 
      configure :description, :string 
      configure :category, :string 
      configure :sort_order, :integer   #   # Sections:
    list do; end
    export do; end
    show do; end
    edit do; end
    create do; end
    update do; end
  end
  config.model Zone do
    # Found associations:
      configure :locations, :has_many_association   #   # Found columns:
      configure :id, :integer 
      configure :name, :string 
      configure :created_at, :datetime 
      configure :updated_at, :datetime 
      configure :short_name, :string 
      configure :is_primary, :boolean   #   # Sections:
    list do; end
    export do; end
    show do; end
    edit do; end
    create do; end
    update do; end
  end
end
