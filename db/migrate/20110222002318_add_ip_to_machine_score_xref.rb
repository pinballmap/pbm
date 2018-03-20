class AddIpToMachineScoreXref < ActiveRecord::Migration[4.2]
  def self.up
    add_column :machine_score_xrefs, :ip, :string
  end

  def self.down
    remove_column :machine_score_xrefs, :ip
  end
end
