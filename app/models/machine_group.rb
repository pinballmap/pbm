class MachineGroup < ApplicationRecord
  has_paper_trail
  belongs_to :machine, optional: true

  validates_presence_of :name
end
