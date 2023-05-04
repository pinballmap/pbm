class CreateStatus < ActiveRecord::Migration[7.0]
  def change
    create_table :statuses do |t|
      t.string :status_type
      t.timestamps
    end
  end
end
