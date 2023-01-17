class AddMachineDisplayToMachines < ActiveRecord::Migration[6.1]
  def change
    add_column :machines, :machine_display, :string
  end
end
