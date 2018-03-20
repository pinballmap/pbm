class RemoveInitalsFromMachineScoreXrefs < ActiveRecord::Migration[4.2]
  def self.up
    remove_column :machine_score_xrefs, :initials
  end

  def self.down
    add_column :machine_score_xrefs, :initials, :string
  end
end
