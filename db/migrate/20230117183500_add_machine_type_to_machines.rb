class AddMachineTypeToMachines < ActiveRecord::Migration[6.1]
  def change
    add_column :machines, :machine_type, :string
  end
end
