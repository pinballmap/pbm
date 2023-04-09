class MachineGroup < ApplicationRecord
  belongs_to :machine, optional: true

  validates_presence_of :name
end
