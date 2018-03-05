class AddIpdbLinkToMachines < ActiveRecord::Migration[4.2]
  def up
    add_column :machines, :ipdb_link, :string
  end
  def down
    remove_column :machines, :ipdb_link
  end
end
