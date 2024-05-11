class MachineCondition < ApplicationRecord
  MAX_HISTORY_SIZE_TO_DISPLAY = 12

  has_paper_trail

  belongs_to :user, optional: true
  belongs_to :location_machine_xref, optional: true, touch: true
  has_one :location, through: :location_machine_xref
  has_one :machine, through: :location_machine_xref
  strip_attributes

  after_create :create_user_submission

  scope :limited, (-> { order('created_at DESC').limit(MachineCondition::MAX_HISTORY_SIZE_TO_DISPLAY) })

  def destroy(options = {})
    if location_machine_xref.machine_conditions.size == 1
      location_machine_xref.condition = nil
      location_machine_xref.condition_date = nil

      location_machine_xref.save(validate: false)
      location_machine_xref
    elsif location_machine_xref.machine_conditions.size > 1 && location_machine_xref.machine_conditions.first == self
      location_machine_xref.condition = location_machine_xref.machine_conditions.second.comment
      location_machine_xref.condition_date = location_machine_xref.machine_conditions.second.updated_at

      location_machine_xref.save(validate: false)
      location_machine_xref
    end

    super()
  end

  def create_user_submission
    user_info = user ? user.username : 'UNKNOWN USER'

    UserSubmission.create(user_name: user&.username, machine_name: machine.name_and_year, location_name: location.name, city_name: location.city, comment: comment, lat: location.lat, lon: location.lon, region_id: location.region_id, location: location, machine: machine, submission_type: UserSubmission::NEW_CONDITION_TYPE, submission: "#{user_info} commented on #{machine.name_and_year} at #{location.name} in #{location.city}. They said: #{comment}", user: user)
  end

  def username
    user ? user.username : ''
  end

  def as_json(options = {})
    options[:methods] = [:username]
    super
  end
end
