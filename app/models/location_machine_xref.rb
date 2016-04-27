class LocationMachineXref < ActiveRecord::Base
  include Rakismet::Model

  rakismet_attrs content: :condition

  belongs_to :location
  belongs_to :machine
  belongs_to :user
  has_many :machine_score_xrefs
  has_many :machine_conditions

  attr_accessible :machine_id, :location_id, :condition, :condition_date, :ip, :user_id

  after_create :update_location

  scope :region, lambda {|name|
    r = Region.find_by_name(name.downcase)
    joins(:location).where('locations.region_id = ?', r.id)
  }

  def haml_object_ref
    'lmx'
  end

  def add_host_info_to_subject(subject, host)
    server_name = host =~ /pinballmapstaging/ ? '(STAGING) ' : ''

    server_name + subject
  end

  def update_condition(condition, options = {})
    return if condition == self.condition

    self.condition = condition
    self.condition_date = Date.today
    location.date_last_updated = Date.today
    location.save(validate: false)

    save

    MachineCondition.create(comment: condition, location_machine_xref: self)

    return if condition.nil? || condition.blank?

    Pony.mail(
      to: location.region.users.map { |u| u.email },
      from: 'admin@pinballmap.com',
      subject: add_host_info_to_subject('PBM - Someone entered a machine condition', options[:request_host]),
      body: [condition, machine.name, location.name, location.region.name, "(entered from #{options[:remote_ip]} via #{options[:user_agent]})"].join("\n")
    )
  end

  def as_json(options = {})
    h = super(options)
    h[:machine_conditions] = machine_conditions.limited

    h
  end

  def sorted_machine_conditions
    # Offset by 1 so that we don't show the current machine condition
    machine_conditions.limited.offset(1)
  end

  def update_location
    location.date_last_updated = Date.today
    location.save(validate: false)
  end

  def destroy(options = {})
    if location.region.should_email_machine_removal
      Pony.mail(
          to: location.region.users.map { |u| u.email },
          from: 'admin@pinballmap.com',
          subject: add_host_info_to_subject('PBM - Someone removed a machine from a location', options[:request_host]),
          body: [location.name, machine.name, location.region.name, "(user_id: #{options[:user_id]}) (entered from #{options[:remote_ip]} via #{options[:user_agent]})"].join("\n")
      )
    end

    UserSubmission.create(region_id: location.region_id, submission_type: UserSubmission::REMOVE_MACHINE_TYPE, submission: ["#{location.name} (#{location.id})", "#{machine.name} (#{machine.id})", "#{location.region.name} (#{location.region.id})"].join("\n"), user_id: options[:user_id])

    location.date_last_updated = Date.today
    location.save(validate: false)
    location

    super()
  end
end
