class AddCategoryAndRegionIdToRegionLinkXref < ActiveRecord::Migration
  def self.up
    add_column :region_link_xrefs, :category, :string
    add_column :region_link_xrefs, :region_id, :integer
  end

  def self.down
    remove_column :region_link_xrefs, :category
    remove_column :region_link_xrefs, :region_id
  end
end
