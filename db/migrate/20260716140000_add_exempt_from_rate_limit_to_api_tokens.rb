class AddExemptFromRateLimitToApiTokens < ActiveRecord::Migration[8.1]
  def change
    add_column :api_tokens, :exempt_from_rate_limit, :boolean, default: false, null: false
  end
end
