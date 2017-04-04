class ReAddRankToMachineScoreXrefs < ActiveRecord::Migration
  def change
    add_column :machine_score_xrefs, :rank, :string
  end
end
