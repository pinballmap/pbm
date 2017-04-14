class CreateMachineComments < ActiveRecord::Migration
  def change
    create_table :machine_comments do |t|
      t.text :comment

      t.references :location_machine_xref, index: true

      t.timestamps
    end
  end
end
