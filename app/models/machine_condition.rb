class MachineCondition < ActiveRecord::Base
  MAX_HISTORY_SIZE_TO_DISPLAY = 6

  belongs_to :location_machine_xref
  has_one :location, through: :location_machine_xref
  has_one :machine, through: :location_machine_xref

  attr_accessible :comment, :location_machine_xref

  scope :limited, -> { order('created_at DESC').limit(MachineCondition::MAX_HISTORY_SIZE_TO_DISPLAY) }
end
