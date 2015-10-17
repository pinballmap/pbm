class AddUserSubmission < ActiveRecord::Migration
  def change
    create_table :user_submissions do |t|
      t.text :submission_type
      t.text :submission

      t.references :region, index: true

      t.timestamps
    end
  end
end
