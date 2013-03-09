class AddManufacturerToMachines < ActiveRecord::Migration
  def up
    add_column :machines, :manufacturer, :string
  end
  def down
    remove_column :machines, :manufacturer
  end
end
