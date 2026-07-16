class CreateApiTokens < ActiveRecord::Migration[7.2]
  def up
    create_table :api_tokens do |t|
      t.integer :user_id, null: false
      t.string :token
      t.text :requested_use, null: false
      t.datetime :approved_at
      t.integer :approved_by_user_id
      t.datetime :disabled_at
      t.string :disabled_reason
      t.integer :disabled_by_user_id
      t.timestamps
    end

    add_index :api_tokens, :user_id
    add_index :api_tokens, :approved_by_user_id
    add_index :api_tokens, :disabled_by_user_id
    add_index :api_tokens, :token, unique: true
    add_index :api_tokens, :user_id, unique: true, where: "disabled_at IS NULL AND approved_at IS NOT NULL", name: "index_api_tokens_on_user_id_active_unique"
  end

  def down
    drop_table :api_tokens
  end
end
