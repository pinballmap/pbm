class RemoveIpFromMachineScoreXrefs < ActiveRecord::Migration[7.0]
  def change
    remove_column :machine_score_xrefs, :ip, :string
  end
end
