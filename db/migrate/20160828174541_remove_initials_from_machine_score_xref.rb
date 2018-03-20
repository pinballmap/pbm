class RemoveInitialsFromMachineScoreXref < ActiveRecord::Migration[4.2]
  def change
    remove_column :machine_score_xrefs, :initials
  end
end
