class MachineGroup < ActiveRecord::Base
  belongs_to :machine

  validates_presence_of :name

  attr_accessible :name
end
