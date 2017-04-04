class AddIpdbLinkToMachines < ActiveRecord::Migration
  def up
    add_column :machines, :ipdb_link, :string
  end
  def down
    remove_column :machines, :ipdb_link
  end
end
