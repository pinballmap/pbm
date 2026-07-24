class AddAllAgesAndPaymentTypeToLocations < ActiveRecord::Migration[8.1]
  def change
    add_column :locations, :all_ages, :text
    add_column :locations, :payment_type, :text
  end
end
