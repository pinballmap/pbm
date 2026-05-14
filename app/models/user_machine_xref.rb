class UserMachineXref < ApplicationRecord
  belongs_to :user
  belongs_to :machine
end
