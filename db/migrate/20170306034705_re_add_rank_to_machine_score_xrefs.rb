class ReAddRankToMachineScoreXrefs < ActiveRecord::Migration[4.2]
  def change
    add_column :machine_score_xrefs, :rank, :string
  end
end
