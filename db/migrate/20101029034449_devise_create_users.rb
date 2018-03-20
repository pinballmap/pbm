class DeviseCreateUsers < ActiveRecord::Migration[4.2]
  def self.up
    create_table(:users) do |t|
      #t.database_authenticatable :null => false
      #t.recoverable
      #t.rememberable
      #t.trackable

      # t.confirmable
      # t.lockable :lock_strategy => :failed_attempts, :unlock_strategy => :both
      # t.token_authenticatable

      t.column :email, :string
      t.column :encrypted_password, :string
      t.column :sign_in_count, :integer
      t.column :current_sign_in_at, :datetime
      t.column :last_sign_in_at, :datetime
      t.column :current_sign_in_ip, :string
      t.column :last_sign_in_ip, :string

      t.timestamps
    end

    add_index :users, :email,                :unique => true
    #add_index :users, :reset_password_token, :unique => true
    # add_index :users, :confirmation_token,   :unique => true
    # add_index :users, :unlock_token,         :unique => true
  end

  def self.down
    drop_table :users
  end
end
