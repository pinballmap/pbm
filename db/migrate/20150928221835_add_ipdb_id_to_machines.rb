class AddIpdbIdToMachines < ActiveRecord::Migration
  def change
    add_column :machines, :ipdb_id, :integer
  end
end
