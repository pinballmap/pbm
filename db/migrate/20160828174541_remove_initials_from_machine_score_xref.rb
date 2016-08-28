class RemoveInitialsFromMachineScoreXref < ActiveRecord::Migration
  def change
    remove_column :machine_score_xrefs, :initials
  end
end
