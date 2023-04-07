class Location < ApplicationRecord
  include Rakismet::Model
  has_paper_trail

  rakismet_attrs content: :description

  validates_presence_of :name, :street, :city, :country
  validates :phone, phone: { possible: true, allow_blank: true }
  validates :website, format: { with: %r{http(s?)://}, message: 'must begin with http:// or https://', multiline: true }, if: :website?
  validates :name, :street, :city, format: { with: /^\S.*/, message: "Can't start with a blank", multiline: true }
  validates :lat, :lon, presence: { message: 'Latitude/Longitude failed to generate. Please double check address and try again, or manually enter the lat/lon' }

  belongs_to :location_type, optional: true
  belongs_to :zone, optional: true
  belongs_to :region, optional: true
  belongs_to :operator, optional: true
  belongs_to :last_updated_by_user, class_name: 'User', foreign_key: 'last_updated_by_user_id', optional: true
  has_many :events
  has_many :location_machine_xrefs
  has_many :location_picture_xrefs
  has_many :machines, through: :location_machine_xrefs
  has_many :machine_conditions, through: :location_machine_xrefs

  geocoded_by :full_street_address, latitude: :lat, longitude: :lon
  before_validation :geocode, unless: :skip_geocoding?

  MAP_SCALE = 0.75

  scope :region, (lambda { |name|
    r = Region.find_by_name(name.downcase) || Region.where(name: 'portland').first
    where(region_id: r.id)
  })
  scope :by_type_id, (->(id) { where('location_type_id in (?)', id.split('_').map(&:to_i)) })
  scope :by_location_id, (->(id) { where('id in (?)', id.split('_').map(&:to_i)) })
  scope :by_operator_id, (->(id) { where('operator_id in (?)', id.split('_').map(&:to_i)) })
  scope :by_zone_id, (->(id) { where('zone_id in (?)', id.split('_').map(&:to_i)) })
  scope :by_city_id, (->(city) { where(city: city) })
  scope :by_state_id, (->(state) { where(state: state) })
  scope :by_location_name, (->(name) { where("lower(regexp_replace(name, '’', '''', 'gi')) ilike ?", '%' + name.downcase.tr('’', "'") + '%') })
  scope :by_ipdb_id, (lambda { |id|
    machines = Machine.where('ipdb_id in (?)', id.split('_').map(&:to_i)).map(&:all_machines_in_machine_group).flatten
    joins(:location_machine_xrefs).where('locations.id = location_machine_xrefs.location_id and location_machine_xrefs.machine_id in (?)', machines.map(&:id))
  })
  scope :by_opdb_id, (lambda { |id|
    machines = Machine.where('opdb_id in (?)', id.split('_')).map(&:all_machines_in_machine_group).flatten
    joins(:location_machine_xrefs).where('locations.id = location_machine_xrefs.location_id and location_machine_xrefs.machine_id in (?)', machines.map(&:id))
  })
  scope :by_machine_id, (lambda { |id|
    machines = Machine.where('id in (?)', id.split('_').map(&:to_i)).map(&:all_machines_in_machine_group).flatten
    joins(:location_machine_xrefs).where('locations.id = location_machine_xrefs.location_id and location_machine_xrefs.machine_id in (?)', machines.map(&:id))
  })
  scope :by_machine_group_id, (lambda { |id|
    machines = Machine.where('machine_group_id in (?)', id)
    joins(:location_machine_xrefs).where('locations.id = location_machine_xrefs.location_id and location_machine_xrefs.machine_id in (?)', machines.map(&:id))
  })
  scope :by_machine_name, (lambda { |name|
    machine = Machine.find_by_name(name)
    return Location.default_scoped.none if machine.nil?

    machines = machine.machine_group_id ? Machine.where('machine_group_id = ?', machine.machine_group_id).map(&:all_machines_in_machine_group).flatten : [machine]
    joins(:location_machine_xrefs).where('locations.id = location_machine_xrefs.location_id and location_machine_xrefs.machine_id in (?)', machines.map(&:id))
  })
  scope :by_at_least_n_machines_city, (lambda { |n|
    where(Location.by_at_least_n_machines_sql(n))
  })
  scope :by_at_least_n_machines_zone, (lambda { |n|
    where(Location.by_at_least_n_machines_sql(n))
  })
  scope :by_at_least_n_machines_type, (lambda { |n|
    where(Location.by_at_least_n_machines_sql(n))
  })
  scope :by_center_point_and_ne_boundary, (lambda { |boundaries|
    boundary_lat_lons = boundaries.split(',').collect(&:to_f)
    distance = Geocoder::Calculations.distance_between([boundary_lat_lons[1], boundary_lat_lons[0]], [boundary_lat_lons[3], boundary_lat_lons[2]])
    box = Geocoder::Calculations.bounding_box([boundary_lat_lons[1], boundary_lat_lons[0]], distance * MAP_SCALE)
    Location.within_bounding_box(box)
  })
  scope :by_is_stern_army, (->(_non_blank_param) { where(is_stern_army: true) })
  scope :regionless_only, (->(_non_blank_param) { where(region_id: nil) })
  scope :zoneless, (-> { where(zone_id: nil) })
  scope :user_faved, (lambda { |user_id|
    fave_ids = UserFaveLocation.where(user_id: user_id).map(&:location_id)
    where(id: fave_ids)
  })
  scope :manufacturer, (lambda { |manufacturer|
    machines = Machine.where('manufacturer = ?', manufacturer)
    joins(:location_machine_xrefs).where('locations.id = location_machine_xrefs.location_id and location_machine_xrefs.machine_id in (?)', machines.map(&:id)).distinct
  })

  before_destroy do |record|
    Event.where(location_id: record.id).destroy_all
    LocationPictureXref.where(location_id: record.id).destroy_all
    MachineScoreXref.where("location_machine_xref_id in (select id from location_machine_xrefs where location_id = #{record.id})").destroy_all
    LocationMachineXref.where(location_id: record.id).destroy_all
    UserFaveLocation.where(location_id: record.id).destroy_all

    UserSubmission.create(region_id: region&.id, location: self, submission_type: UserSubmission::DELETE_LOCATION_TYPE, submission: "Deleted #{name} (#{id})")
  end

  def skip_geocoding?
    ENV['SKIP_GEOCODE'] || (lat && lon)
  end

  def self.by_at_least_n_machines_sql(number_of_machines)
    "locations.id in (select location_id from (select location_id, count(*) as count from location_machine_xrefs group by location_id) x where x.count >= #{number_of_machines})"
  end

  def user_fave?(user_id)
    UserFaveLocation.where(user_id: user_id, location_id: id).any?
  end

  def num_machines
    machines.length
  end

  def machine_names
    machines.sort_by(&:massaged_name).map(&:name_and_year)
  end

  def machine_ids
    machines.sort_by(&:massaged_name).map(&:id)
  end

  def content_for_infowindow
    content = "'<div class=\"infowindow\" id=\"infowindow_#{id}\">"
    content += "<div class=\"gm_location_name\">#{name.gsub("'", "\\\\'")}</div>"
    content += "<div class=\"gm_address\">#{[street.gsub("'", "\\\\'"), [city.gsub("'", "\\\\'"), state, zip].compact.split('').flatten.join(', '), phone].join('<br />')}</div>"
    content += '<hr />'

    machines = machine_names.take(5).map { |m| m.gsub("'", "\\\\'") + '<br />' }
    total_num_machines = machine_names.size

    content += "<div class=\"gm_machines\" id=\"gm_machines_#{id}\">#{machines.join}"
    if total_num_machines > 5
      the_rest = total_num_machines - 5
      content += "<div>... and #{the_rest} more</div>"
    end
    content += "</div></div>'"

    content.html_safe
  end

  def recent_activity
    UserSubmission.where.not(submission_type: 'location_metadata', location_id: self).where(location_id: self, created_at: '2019-05-03T07:00:00.00-07:00'..Date.today.end_of_day).order('created_at DESC')
  end

  def full_street_address
    [street, city, state, zip].join(', ')
  end

  def newest_machine_xref
    location_machine_xrefs.max_by(&:created_at)
  end

  def massaged_name
    name.sub(/^the /i, '')
  end

  def update_description(new_description)
    old_description = description
    self.description = new_description.slice(0, 549)

    if !description.match?(%r{http(s?)://})
      if ENV['RAKISMET_KEY'] && spam?
        self.description = old_description
        @validation_errors.push('This description was flagged as spam. ')
      else
        @updates.push('Changed location description to ' + description)
      end
    else
      self.description = old_description
      @validation_errors.push('Location descriptions cannot include http. Please try again. ')
    end
  end

  def update_phone(new_phone)
    old_phone = phone
    if new_phone && !new_phone.blank?
      self.phone = new_phone.empty? ? 'empty' : new_phone

      if valid?
        @updates.push('Changed phone # to ' + phone)
      else
        self.phone = old_phone
        @validation_errors.push('Invalid phone format.')
      end
    elsif new_phone&.blank?
      self.phone = nil
    end
  end

  def update_website(new_website)
    old_website = website
    self.website = new_website

    if valid?
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

    @validation_errors.push('This update was flagged as spam.') if ENV['RAKISMET_KEY'] && spam?

    @validation_errors.push('Invalid') unless valid?

    if save && errors.count.zero? && @validation_errors.empty?
      self.date_last_updated = Date.today
      self.last_updated_by_user_id = user&.id
      save

      UserSubmission.create(region_id: region&.id, location: self, submission_type: UserSubmission::LOCATION_METADATA_TYPE, submission: @updates.join("\n") + " to #{name}", user_id: user&.id)

      [self, 'location']
    else
      [(@validation_errors + errors.full_messages).uniq, 'errors']
    end
  end

  def name_and_city
    name + ' (' + city + ')'
  end

  def last_updated_by_username
    last_updated_by_user ? last_updated_by_user.username : ''
  end

  def confirm(user)
    self.date_last_updated = Date.today
    self.last_updated_by_user = user

    UserSubmission.create(user_name: user&.username, location_name: name, city_name: city, region_id: region&.id, location: self, submission_type: UserSubmission::CONFIRM_LOCATION_TYPE, submission: "#{user ? user.username : 'Someone'} confirmed the lineup at #{name} in #{city}", user: user)

    save(validate: false)
  end
end
