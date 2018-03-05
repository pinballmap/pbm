class AddManufacturerToMachines < ActiveRecord::Migration[4.2]
  def up
    add_column :machines, :manufacturer, :string
  end
  def down
    remove_column :machines, :manufacturer
  end
end
