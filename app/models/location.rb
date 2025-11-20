class Location < ApplicationRecord
  has_paper_trail only: %i[name street city state region zone lat lon is_stern_army]

  validates_presence_of :name, :street, :city, :country
  validates :phone, phone: { possible: true, allow_blank: true, message: "Phone format not valid." }
  validates :website, format: { with: %r{\Ahttp(s?)://}, message: "must begin with http:// or https://" }, if: :website?
  validates :name, :street, :city, format: { with: /\A\S.*/, message: "Can't start with a blank", multiline: true }
  validates :lat, :lon, presence: { message: "Latitude/Longitude failed to generate. Please double check address and try again, or manually enter the lat/lon" }

  belongs_to :location_type, optional: true
  belongs_to :zone, optional: true
  belongs_to :region, optional: true
  belongs_to :operator, optional: true
  belongs_to :last_updated_by_user, class_name: "User", foreign_key: "last_updated_by_user_id", optional: true
  has_many :events
  has_many :location_machine_xrefs
  has_many :location_picture_xrefs
  has_many :machines, through: :location_machine_xrefs

  geocoded_by :full_street_address, latitude: :lat, longitude: :lon
  before_validation :geocode, unless: :skip_geocoding?
  strip_attributes

  MAP_SCALE = 0.75

  scope :region, lambda { |name|
    r = Region.find_by_name(name.downcase) || Region.where(name: "portland").first
    where(region_id: r.id)
  }
  scope :by_type_id, ->(id) { where("location_type_id in (?)", id.split("_").map(&:to_i)) }
  scope :by_location_id, ->(id) { where("id in (?)", id.split("_").map(&:to_i)) }
  scope :by_operator_id, ->(id) { where("operator_id in (?)", id.split("_").map(&:to_i)) }
  scope :by_zone_id, ->(id) { where("zone_id in (?)", id.split("_").map(&:to_i)) }
  scope :by_city_id, ->(city) { where(city: city) }
  scope :by_state_id, ->(state) { where(state: state) }
  scope :by_country, ->(country) { where(country: country) }
  scope :by_city_name, ->(city) { where(city: city) }
  scope :by_city_no_state, ->(city) { where(city: city).where(state: nil) }
  scope :by_state_name, ->(state) { where(state: state) }
  scope :by_location_name, ->(name) { where("lower(regexp_replace(name, '’', '''', 'gi')) ilike ?", "%" + name.downcase.tr("’", "'") + "%") }
  scope :by_ipdb_id, lambda { |id|
    machines = Machine.where("ipdb_id in (?)", id.split("_").map(&:to_i)).map(&:all_machines_in_machine_group).flatten
    joins(:location_machine_xrefs).where("locations.id = location_machine_xrefs.location_id and location_machine_xrefs.machine_id in (?)", machines.map(&:id))
  }
  scope :by_opdb_id, lambda { |id|
    machines = Machine.where("opdb_id in (?)", id.split("_")).map(&:all_machines_in_machine_group).flatten
    joins(:location_machine_xrefs).where("locations.id = location_machine_xrefs.location_id and location_machine_xrefs.machine_id in (?)", machines.map(&:id))
  }
  scope :by_machine_id, lambda { |id|
    machines = Machine.where("id in (?)", id.split("_").map(&:to_i)).map(&:all_machines_in_machine_group).flatten
    joins(:location_machine_xrefs).where("locations.id = location_machine_xrefs.location_id and location_machine_xrefs.machine_id in (?)", machines.map(&:id))
  }
  scope :by_machine_group_id, lambda { |id|
    machines = Machine.where("machine_group_id in (?)", id.split("_").map(&:to_i))
    joins(:location_machine_xrefs).where("locations.id = location_machine_xrefs.location_id and location_machine_xrefs.machine_id in (?)", machines.map(&:id))
  }
  scope :by_machine_single_id, lambda { |id|
    machine = Machine.where("id in (?)", id.split("_").map(&:to_i))
    joins(:location_machine_xrefs).where("locations.id = location_machine_xrefs.location_id and location_machine_xrefs.machine_id in (?)", machine.map(&:id))
  }
  scope :by_machine_id_ic, lambda { |id|
    machines = Machine.where("id in (?)", id.split("_")).map(&:all_machines_in_machine_group).flatten
    joins(:location_machine_xrefs).where("locations.id = location_machine_xrefs.location_id and location_machine_xrefs.ic_enabled = true and location_machine_xrefs.machine_id in (?)", machines.map(&:id))
  }
  scope :by_machine_single_id_ic, lambda { |id|
    machine = Machine.where("id in (?)", id.split("_").map(&:to_i))
    joins(:location_machine_xrefs).where("locations.id = location_machine_xrefs.location_id and location_machine_xrefs.ic_enabled = true and location_machine_xrefs.machine_id in (?)", machine.map(&:id))
  }
  scope :by_machine_year, lambda { |id|
    machines = Machine.where("year in (?)", id.split("_").map(&:to_i))
    joins(:location_machine_xrefs).where("locations.id = location_machine_xrefs.location_id and location_machine_xrefs.machine_id in (?)", machines.map(&:id)).distinct
  }
  scope :by_machine_name, lambda { |name|
    machine = Machine.find_by_name(name)
    return Location.default_scoped.none if machine.nil?

    machines = machine.machine_group_id ? Machine.where("machine_group_id = ?", machine.machine_group_id).map(&:all_machines_in_machine_group).flatten : [ machine ]
    joins(:location_machine_xrefs).where("locations.id = location_machine_xrefs.location_id and location_machine_xrefs.machine_id in (?)", machines.map(&:id))
  }

  scope :by_at_least_n_machines, ->(machine_count) { where("machine_count >= ?", machine_count) }

  scope :by_at_least_n_machines_city, ->(machine_count) { where("machine_count >= ?", machine_count) }

  scope :by_at_least_n_machines_name, ->(machine_count) { where("machine_count >= ?", machine_count) }

  scope :by_at_least_n_machines_type, ->(machine_count) { where("machine_count >= ?", machine_count) }

  scope :by_at_least_n_machines_zone, ->(machine_count) { where("machine_count >= ?", machine_count) }

  scope :by_center_point_and_ne_boundary, lambda { |boundaries|
    boundary_lat_lons = boundaries.split(",").collect(&:to_f)
    distance = Geocoder::Calculations.distance_between([ boundary_lat_lons[1], boundary_lat_lons[0] ], [ boundary_lat_lons[3], boundary_lat_lons[2] ])
    box = Geocoder::Calculations.bounding_box([ boundary_lat_lons[1], boundary_lat_lons[0] ], distance * MAP_SCALE)
    Location.within_bounding_box(box)
  }
  scope :by_is_stern_army, ->(_non_blank_param) { where(is_stern_army: true) }
  scope :by_ic_active, ->(_non_blank_param) { where(ic_active: true) }
  scope :regionless_only, ->(_non_blank_param) { where(region_id: nil) }
  scope :zoneless, -> { where(zone_id: nil) }
  scope :user_faved, lambda { |user_id|
    fave_ids = UserFaveLocation.where(user_id: user_id).map(&:location_id)
    where(id: fave_ids)
  }
  scope :manufacturer, lambda { |manufacturer|
    machines = Machine.where("manufacturer in (?)", manufacturer.split("_").map(&:to_s))
    joins(:location_machine_xrefs).where("locations.id = location_machine_xrefs.location_id and location_machine_xrefs.machine_id in (?)", machines.map(&:id)).distinct
  }
  scope :by_machine_type, lambda { |machine_type|
    machines = Machine.where("machine_type in (?)", machine_type.split("_").map(&:to_s))
    joins(:location_machine_xrefs).where("locations.id = location_machine_xrefs.location_id and location_machine_xrefs.machine_id in (?)", machines.map(&:id)).distinct
  }
  scope :by_machine_display, lambda { |machine_display|
    machines = Machine.where("machine_display in (?)", machine_display.split("_").map(&:to_s))
    joins(:location_machine_xrefs).where("locations.id = location_machine_xrefs.location_id and location_machine_xrefs.machine_id in (?)", machines.map(&:id)).distinct
  }

  before_destroy do |record|
    Event.where(location_id: record.id).destroy_all
    LocationPictureXref.where(location_id: record.id).destroy_all
    MachineScoreXref.where("location_machine_xref_id in (select id from location_machine_xrefs where location_id = #{record.id})").destroy_all
    LocationMachineXref.where(location_id: record.id).destroy_all
    UserFaveLocation.where(location_id: record.id).destroy_all

    UserSubmission.create(region_id: region&.id, location: self, submission_type: UserSubmission::DELETE_LOCATION_TYPE, submission: "Deleted #{name} (#{id})")
  end

  def skip_geocoding?
    ENV["SKIP_GEOCODE"] || (lat && lon)
  end

  def user_fave?(user_id)
    UserFaveLocation.where(user_id: user_id, location_id: id).any?
  end

  def num_machines
    machine_count
  end

  def machine_names
    machines.sort_by(&:massaged_name).map(&:name_and_year)
  end

  def machine_names_first
    machines.take(5).sort_by(&:massaged_name).map(&:name_and_year)
  end

  def machine_names_first_no_year
    machines.take(5).sort_by(&:massaged_name).map(&:massaged_name)
  end

  def machine_ids
    machines.sort_by(&:massaged_name).map(&:id)
  end

  def recent_activity
    UserSubmission.where(submission_type: %w[new_lmx remove_machine new_condition confirm_location], location_id: self, created_at: "2019-05-03T07:00:00.00-07:00"..Date.today.end_of_day, deleted_at: nil).order("created_at DESC").limit(50)
  end

  def former_machines
    UserSubmission.where.not(machine_name: nil).where(submission_type: "remove_machine", location_id: self, created_at: "2019-05-03T07:00:00.00-07:00"..Date.today.end_of_day, deleted_at: nil).where(location_id: self).order("created_at DESC").limit(30)
  end

  def full_street_address
    [ street, city, state, zip ].compact.join(", ")
  end

  # returns "city, state" if state is available otherwise just city
  def city_and_state
    state_str = ", #{state}" unless state.blank?
    "#{city}#{state_str}"
  end

  def massaged_name
    name.sub(/^the /i, "")
  end

  def update_description(new_description)
    old_description = description
    self.description = new_description.slice(0, 549)

    if !description.match?(%r{http(s?)://})
      @updates.push("Changed location description to " + description)
    else
      self.description = old_description
      @validation_errors.push("Location descriptions cannot include http. Please try again. ")
    end
  end

  def update_phone(new_phone)
    old_phone = phone
    if new_phone && !new_phone.blank?
      self.phone = new_phone.empty? ? "empty" : new_phone

      if valid?
        @updates.push("Changed phone # to " + phone)
      else
        self.phone = old_phone
        @validation_errors.push("Invalid phone format.")
      end
    elsif new_phone&.blank?
      self.phone = nil
    end
  end

  def update_website(new_website)
    old_website = website
    if new_website && !new_website.blank?
      self.website = new_website

      if valid?
        @updates.push("Changed website to " + website)
      else
        self.website = old_website
        @validation_errors.push("Website must begin with http:// or https://")
      end
    elsif new_website&.blank?
      self.website = nil
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

    @validation_errors.push("Invalid") unless valid?

    if save && errors.count.zero? && @validation_errors.empty?
      self.date_last_updated = Date.today
      self.last_updated_by_user_id = user&.id
      save

      UserSubmission.create(region_id: region&.id, location: self, submission_type: UserSubmission::LOCATION_METADATA_TYPE, submission: @updates.join("\n") + " to #{name}", user_id: user&.id)
      self.users_count = UserSubmission.where(location_id: self.id).count("DISTINCT user_id")
      save(validate: false)

      [ self, "location" ]
    else
      [ (@validation_errors + errors.full_messages).uniq, "errors" ]
    end
  end

  def name_and_city
    name + " (" + city + ")"
  end

  def last_updated_by_username
    last_updated_by_user ? last_updated_by_user.username : ""
  end

  def confirm(user)
    recent_confirm = UserSubmission.where(submission_type: "confirm_location", location: self).order(created_at: :desc).pluck(:created_at).first

    recent_add_remove = UserSubmission.where(submission_type: %w[new_lmx remove_machine], location: self).order(created_at: :desc).pluck(:created_at).first

    self.date_last_updated = Date.today
    self.last_updated_by_user = user

    if recent_confirm.blank? || recent_add_remove.blank? || recent_confirm < recent_add_remove || recent_confirm < 7.days.ago.beginning_of_day

      submission = "#{user ? user.username : 'Someone'} confirmed the lineup at #{name} in #{city}"

      UserSubmission.create(user_name: user&.username, location_name: name, city_name: city, lat: lat, lon: lon, region_id: region&.id, location: self, submission_type: UserSubmission::CONFIRM_LOCATION_TYPE, submission: submission, user: user)
      Rails.logger.info "USER SUBMISSION USER ID #{user&.id} #{submission}"
      self.users_count = UserSubmission.where(location_id: self.id).count("DISTINCT user_id")

      save(validate: false)
    end
  end
end
