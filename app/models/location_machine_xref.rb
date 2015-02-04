class LocationMachineXref < ActiveRecord::Base
  belongs_to :location
  belongs_to :machine
  belongs_to :user
  has_many :machine_score_xrefs
  has_many :machine_conditions

  attr_accessible :machine_id, :location_id, :condition, :condition_date, :ip, :user_id

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
    self.condition = condition
    self.condition_date = Time.now.strftime('%Y-%m-%d')
    save

    return if condition.nil? || condition.blank?

    MachineCondition.create(comment: condition, location_machine_xref: self)

    Pony.mail(
      to: location.region.users.map { |u| u.email },
      from: 'admin@pinballmap.com',
      subject: add_host_info_to_subject('PBM - Someone entered a machine condition', options[:request_host]),
      body: [condition, machine.name, location.name, location.region.name, "(entered from #{options[:remote_ip]} via #{options[:user_agent]})"].join("\n")
    )
  end

  def sorted_machine_conditions
    # Offset by 1 so that we don't show the current machine condition
    return self.machine_conditions.order('created_at DESC').offset(1)
  end

  def destroy(options = {})
    if location.region.should_email_machine_removal
      Pony.mail(
          to: location.region.users.map { |u| u.email },
          from: 'admin@pinballmap.com',
          subject: add_host_info_to_subject('PBM - Someone removed a machine from a location', options[:request_host]),
          body: [location.name, machine.name, location.region.name, "(entered from #{options[:remote_ip]} via #{options[:user_agent]})"].join("\n")
      )
    end

    super()
  end
end
