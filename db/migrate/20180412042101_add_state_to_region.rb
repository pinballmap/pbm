class AddStateToRegion < ActiveRecord::Migration[5.1]
  def change
    add_column :regions, :state, :text
  end
end
