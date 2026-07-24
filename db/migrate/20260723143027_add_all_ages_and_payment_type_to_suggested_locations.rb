class AddAllAgesAndPaymentTypeToSuggestedLocations < ActiveRecord::Migration[8.1]
  def change
    add_column :suggested_locations, :all_ages, :text
    add_column :suggested_locations, :payment_type, :text
  end
end
