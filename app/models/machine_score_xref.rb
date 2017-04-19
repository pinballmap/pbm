class MachineScoreXref < ActiveRecord::Base
  belongs_to :user
  belongs_to :location_machine_xref, counter_cache: true
  has_one :location, through: :location_machine_xref
  has_one :machine, through: :location_machine_xref

  attr_accessible :score, :location_machine_xref_id

  scope :zone_id, (lambda { |id|
    joins(:location_machine_xref).joins(:location).where("
      locations.zone_id = #{id}
    ")
  })

  scope :region, (lambda { |name|
    r = Region.find_by_name(name)
    joins(:location_machine_xref).joins(:location).where("
      location_machine_xrefs.id = machine_score_xrefs.location_machine_xref_id
      and locations.id = location_machine_xrefs.location_id
      and locations.region_id = #{r.id}
    ")
  })

  def username
    user ? user.username : ''
  end

  def create_user_submission
    user_info = user ? "User #{user.username} (#{user.email})" : 'UNKNOWN USER'

    UserSubmission.create(region_id: location.region_id, location: location, machine: machine, submission_type: UserSubmission::NEW_SCORE_TYPE, submission: "#{user_info} added a score of #{score} for #{machine.name} to #{location.name}", user: user)
  end
end
