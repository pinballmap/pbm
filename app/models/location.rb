class Location < ActiveRecord::Base
  include Rakismet::Model

  rakismet_attrs content: :description

  validates_presence_of :name, :street, :city, :state, :zip
  validates :phone, format: { with: /\d{3}-\d{3}-\d{4}/, message: 'format invalid, please use ###-###-####' }, if: :phone?
  validates :website, format: { with: %r{^http[s]?:\/\/}, message: 'must begin with http:// or https://', multiline: true }, if: :website?
  validates :name, :street, :city, :state, format: { with: /^\S.*/, message: "Can't start with a blank", multiline: true }
  validates :lat, :lon, presence: { message: 'Latitude/Longitude failed to generate. Please double check address and try again, or manually enter the lat/lon' }

  belongs_to :location_type
  belongs_to :zone
  belongs_to :region
  belongs_to :operator
  belongs_to :last_updated_by_user, class_name: 'User', foreign_key: 'last_updated_by_user_id'
  has_many :events
  has_many :machines, through: :location_machine_xrefs
  has_many :location_machine_xrefs
  has_many :location_picture_xrefs

  geocoded_by :full_street_address, latitude: :lat, longitude: :lon
  before_validation :geocode, unless: ENV['SKIP_GEOCODE'] || (:lat && :lon)

  scope :region, lambda {|name|
    r = Region.find_by_name(name.downcase) || Region.where(name: 'portland').first

    where(region_id: r.id)
  }
  scope :by_type_id, ->(id) { where('location_type_id in (?)', id.split('_').map(&:to_i)) }
  scope :by_location_id, ->(id) { where('id in (?)', id.split('_').map(&:to_i)) }
  scope :by_operator_id, ->(id) { where('operator_id in (?)', id.split('_').map(&:to_i)) }
  scope :by_zone_id, ->(id) { where('zone_id in (?)', id.split('_').map(&:to_i)) }
  scope :by_city_id, ->(city) { where(city: city) }
  scope :by_location_name, ->(name) { where(name: name) }
  scope :by_ipdb_id, lambda { |id|
    machines = Machine.where('ipdb_id in (?)', id.split('_').map(&:to_i)).map { |m| m.all_machines_in_machine_group }.flatten

    joins(:location_machine_xrefs).where('locations.id = location_machine_xrefs.location_id and location_machine_xrefs.machine_id in (?)', machines.map { |m| m.id })
  }
  scope :by_machine_id, lambda { |id|
    machines = Machine.where('id in (?)', id.split('_').map(&:to_i)).map { |m| m.all_machines_in_machine_group }.flatten

    joins(:location_machine_xrefs).where('locations.id = location_machine_xrefs.location_id and location_machine_xrefs.machine_id in (?)', machines.map { |m| m.id })
  }
  scope :by_machine_group_id, lambda { |id|
    machines = Machine.where('machine_group_id in (?)', id).flatten

    joins(:location_machine_xrefs).where('locations.id = location_machine_xrefs.location_id and location_machine_xrefs.machine_id in (?)', machines.map { |m| m.id })
  }
  scope :by_machine_name, lambda { |name|
    machine = Machine.find_by_name(name)

    return nil if machine.nil?

    machines = machine.machine_group_id ? Machine.where('machine_group_id = ?', machine.machine_group_id).map { |m| m.all_machines_in_machine_group }.flatten : [machine]

    joins(:location_machine_xrefs).where('locations.id = location_machine_xrefs.location_id and location_machine_xrefs.machine_id in (?)', machines.map { |m| m.id })
  }
  scope :by_at_least_n_machines_city, lambda { |n|
    where(Location.by_at_least_n_machines_sql(n))
  }
  scope :by_at_least_n_machines_zone, lambda { |n|
    where(Location.by_at_least_n_machines_sql(n))
  }
  scope :by_at_least_n_machines_type, lambda { |n|
    where(Location.by_at_least_n_machines_sql(n))
  }

  attr_accessible :name, :street, :city, :state, :zip, :phone, :lat, :lon, :website, :zone_id, :region_id, :location_type_id, :description, :operator_id, :date_last_updated, :last_updated_by_user_id

  before_destroy do |record|
    Event.destroy_all "location_id = #{record.id}"
    LocationPictureXref.destroy_all "location_id = #{record.id}"
    MachineScoreXref.destroy_all "location_machine_xref_id in (select id from location_machine_xrefs where location_id = #{record.id})"
    LocationMachineXref.destroy_all "location_id = #{record.id}"
  end

  def self.by_at_least_n_machines_sql(n)
    "id in (select location_id from (select location_id, count(*) as count from location_machine_xrefs group by location_id) x where x.count >= #{n})"
  end

  def machine_names
    machines.sort_by(&:massaged_name).map { |m| m.name_and_year }
  end

  def content_for_infowindow
    content = "'<div class=\"infowindow\" id=\"infowindow_#{id}\">"
    content += "<div class=\"gm_location_name\">#{name.gsub("'", "\\\\'")}</div>"
    content += "<div class=\"gm_address\">#{[street.gsub("'", "\\\\'"), [city.gsub("'", "\\\\'"), state, zip].join(', '), phone].join('<br />')}</div>"
    content += '<hr />'

    machines = machine_names.map { |m| m.gsub("'", "\\\\'") + '<br />' }

    content += "<div class=\"gm_machines\" id=\"gm_machines_#{id}\">#{machines.join}</div>"
    content += "</div>'"

    content.html_safe
  end

  def full_street_address
    [street, city, state, zip].join(', ')
  end

  def newest_machine_xref
    location_machine_xrefs.sort_by(&:created_at).last
  end

  def massaged_name
    name.sub(/^the /i, '')
  end

  def update_description(new_description)
    old_description = description
    self.description = new_description.slice(0, 254)

    if description !~ %r{http[s]?:\/\/}
      if ENV['RAKISMET_KEY'] && self.spam?
        self.description = old_description
        @validation_errors.push('This description was flagged as spam.')
      else
        @updates.push('Changed location description to ' + description)
      end
    else
      self.description = old_description
      @validation_errors.push('This description was flagged as spam.')
    end
  end

  def update_phone(new_phone)
    old_phone = phone
    if new_phone && !new_phone.blank?
      new_phone.gsub!(/\s+/, '')
      new_phone.gsub!(/[^0-9]/, '')

      self.phone = new_phone.empty? ? 'empty' : ActionController::Base.helpers.number_to_phone(new_phone)

      if valid?
        @updates.push('Changed phone # to ' + phone)
      else
        self.phone = old_phone
        @validation_errors.push('Phone format invalid, please use ###-###-####')
      end
    elsif new_phone && new_phone.blank?
      self.phone = nil
    end
  end

  def update_website(new_website)
    old_website = website
    self.website = new_website

    if self.valid?
      @updates.push('Changed website to ' + website)
    else
      self.website = old_website
      @validation_errors.push('Website must begin with http:// or https://')
    end
  end

  def update_operator(operator_id)
    @updates.push("Changed operator to #{!operator_id.blank? ? Operator.find(operator_id).name : 'BLANK'}")
    self.operator_id = operator_id
  end

  def update_location_type(location_type_id)
    @updates.push("Changed location type to #{!location_type_id.blank? ? LocationType.find(location_type_id).name : 'BLANK'}")
    self.location_type_id = location_type_id
  end

  def update_metadata(user, options = {})
    @updates = []
    @validation_errors = []

    update_description(options[:description]) if options[:description]
    update_phone(options[:phone]) if options[:phone]
    update_website(options[:website]) if options[:website]
    update_operator(options[:operator_id]) if options[:operator_id]
    update_location_type(options[:location_type_id]) if options[:location_type_id]

    if ENV['RAKISMET_KEY'] && self.spam?
      @validation_errors.push('This update was flagged as spam.')
    end

    @validation_errors.push('Invalid') unless self.valid?

    if save && errors.count == 0 && @validation_errors.empty?
      self.date_last_updated = Date.today
      self.last_updated_by_user_id = user ? user.id : nil
      save

      UserSubmission.create(region_id: region.id, submission_type: UserSubmission::LOCATION_METADATA_TYPE, submission: @updates.join("\n"), user_id: user ? user.id : nil)

      [self, 'location']
    else
      [(@validation_errors + errors.full_messages).uniq, 'errors']
    end
  end
end
