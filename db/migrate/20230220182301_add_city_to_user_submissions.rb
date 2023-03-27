class AddCityToUserSubmissions < ActiveRecord::Migration[6.1]
  def change
    add_column :user_submissions, :city_name, :string
  end
end
