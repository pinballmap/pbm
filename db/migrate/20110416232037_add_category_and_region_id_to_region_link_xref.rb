class AddCategoryAndRegionIdToRegionLinkXref < ActiveRecord::Migration[4.2]
  def self.up
    add_column :region_link_xrefs, :category, :string
    add_column :region_link_xrefs, :region_id, :integer
  end

  def self.down
    remove_column :region_link_xrefs, :category
    remove_column :region_link_xrefs, :region_id
  end
end
