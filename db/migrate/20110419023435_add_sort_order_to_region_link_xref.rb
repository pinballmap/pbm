class AddSortOrderToRegionLinkXref < ActiveRecord::Migration
  def self.up
    add_column :region_link_xrefs, :sort_order, :integer
  end

  def self.down
    remove_column :region_link_xrefs, :sort_order
  end
end
