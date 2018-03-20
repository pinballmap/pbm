class AddInitialsToMachineScoreXrefs < ActiveRecord::Migration[4.2]
  def self.up
    add_column :machine_score_xrefs, :initials, :string
  end

  def self.down
    remove_column :machine_score_xrefs, :initials
  end
end
