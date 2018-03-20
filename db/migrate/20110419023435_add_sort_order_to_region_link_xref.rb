class AddSortOrderToRegionLinkXref < ActiveRecord::Migration[4.2]
  def self.up
    add_column :region_link_xrefs, :sort_order, :integer
  end

  def self.down
    remove_column :region_link_xrefs, :sort_order
  end
end
