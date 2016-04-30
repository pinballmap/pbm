class MachineCondition < ActiveRecord::Base
  MAX_HISTORY_SIZE_TO_DISPLAY = 6

  belongs_to :user
  belongs_to :location_machine_xref
  has_one :location, through: :location_machine_xref
  has_one :machine, through: :location_machine_xref

  attr_accessible :comment, :location_machine_xref, :user, :user_id

  scope :limited, -> { order('created_at DESC').limit(MachineCondition::MAX_HISTORY_SIZE_TO_DISPLAY) }
end
