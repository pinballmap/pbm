# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20110428031156) do

  create_table "events", :force => true do |t|
    t.integer  "region_id"
    t.string   "name"
    t.text     "long_desc"
    t.string   "link"
    t.integer  "category_no"
    t.date     "start_date"
    t.date     "end_date"
    t.integer  "location_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "histories", :force => true do |t|
    t.string   "message"
    t.string   "username"
    t.integer  "item"
    t.string   "table"
    t.integer  "month",      :limit => 2
    t.integer  "year",       :limit => 8
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "histories", ["item", "table", "month", "year"], :name => "index_histories_on_item_and_table_and_month_and_year"

  create_table "location_machine_xrefs", :force => true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "location_id"
    t.integer  "machine_id"
    t.text     "condition"
    t.date     "condition_date"
    t.integer  "operator_id"
    t.string   "ip"
    t.integer  "user_id"
  end

  add_index "location_machine_xrefs", ["location_id"], :name => "index_location_machine_xrefs_on_location_id"
  add_index "location_machine_xrefs", ["machine_id"], :name => "index_location_machine_xrefs_on_machine_id"

  create_table "location_picture_xrefs", :force => true do |t|
    t.integer  "location_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "photo"
    t.text     "description"
    t.boolean  "approved"
    t.integer  "user_id"
  end

  create_table "locations", :force => true do |t|
    t.string   "name"
    t.string   "street"
    t.string   "city"
    t.string   "state"
    t.string   "zip"
    t.string   "phone"
    t.float    "lat"
    t.float    "lon"
    t.string   "website"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "zone_id"
    t.integer  "region_id"
  end

  create_table "machine_score_xrefs", :force => true do |t|
    t.integer  "location_machine_xref_id"
    t.integer  "score",                    :limit => 8
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "rank"
    t.string   "ip"
    t.integer  "user_id"
  end

  add_index "machine_score_xrefs", ["location_machine_xref_id"], :name => "index_machine_score_xrefs_on_location_machine_xref_id"

  create_table "machines", :force => true do |t|
    t.string   "name"
    t.boolean  "is_active"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "operators", :force => true do |t|
    t.string   "name"
    t.integer  "region_id"
    t.string   "email"
    t.string   "website"
    t.string   "phone"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "region_link_xrefs", :force => true do |t|
    t.string  "name"
    t.string  "url"
    t.string  "description"
    t.string  "category"
    t.integer "region_id"
    t.integer "sort_order"
  end

  create_table "regions", :force => true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "full_name"
    t.string   "motd"
    t.float    "lat"
    t.float    "lon"
    t.integer  "n_search_no"
  end

  create_table "users", :force => true do |t|
    t.string   "email",                               :default => "", :null => false
    t.string   "encrypted_password",   :limit => 128, :default => "", :null => false
    t.string   "password_salt",                       :default => "", :null => false
    t.string   "reset_password_token"
    t.string   "remember_token"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",                       :default => 0
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "region_id"
    t.string   "initials"
  end

  add_index "users", ["email"], :name => "index_users_on_email", :unique => true
  add_index "users", ["reset_password_token"], :name => "index_users_on_reset_password_token", :unique => true

  create_table "zones", :force => true do |t|
    t.string   "name"
    t.integer  "region_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "short_name"
    t.boolean  "is_primary"
  end

end
