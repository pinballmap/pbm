class AddIcEligibleToMachines < ActiveRecord::Migration[6.1]
  def change
    add_column :machines, :ic_eligible, :boolean
  end
end
