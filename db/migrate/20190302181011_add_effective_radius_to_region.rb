class AddEffectiveRadiusToRegion < ActiveRecord::Migration[5.2]
  def change
    add_column :regions, :effective_radius, :float, default: 200.0
  end
end
