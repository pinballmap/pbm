class AddIpdbIdToMachines < ActiveRecord::Migration[4.2]
  def change
    add_column :machines, :ipdb_id, :integer
  end
end
