class AddResetPasswordSentAtToUsers < ActiveRecord::Migration[4.2]
  def up
    add_column :users, :reset_password_sent_at, :datetime
  end

  def down
    remove_column :users, :reset_password_sent_at
  end
end
