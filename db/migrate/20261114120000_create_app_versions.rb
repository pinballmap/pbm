class CreateAppVersions < ActiveRecord::Migration[8.1]
  def change
    create_table :app_versions do |t|
      t.string :platform, null: false
      t.string :latest, null: false
      t.timestamps
    end
    add_index :app_versions, :platform, unique: true
  end
end
