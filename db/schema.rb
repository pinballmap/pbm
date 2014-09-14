# encoding: UTF-8
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
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20140913204322) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "banned_ips", force: true do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string   "ip_address"
  end

  create_table "events", force: true do |t|
    t.integer  "region_id"
    t.string   "name"
    t.text     "long_desc"
    t.string   "external_link"
    t.integer  "category_no"
    t.date     "start_date"
    t.date     "end_date"
    t.integer  "location_id"
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
    t.string   "category"
    t.string   "external_location_name"
    t.integer  "ifpa_calendar_id"
    t.integer  "ifpa_tournament_id"
  end

  create_table "location_machine_xrefs", force: true do |t|
    t.datetime "created_at",                null: false
    t.datetime "updated_at",                null: false
    t.integer  "location_id"
    t.integer  "machine_id"
    t.text     "condition"
    t.date     "condition_date"
    t.string   "ip"
    t.integer  "user_id"
    t.integer  "machine_score_xrefs_count"
  end

  add_index "location_machine_xrefs", ["location_id"], name: "index_location_machine_xrefs_on_location_id", using: :btree
  add_index "location_machine_xrefs", ["machine_id"], name: "index_location_machine_xrefs_on_machine_id", using: :btree

  create_table "location_picture_xrefs", force: true do |t|
    t.integer  "location_id"
    t.datetime "created_at",         null: false
    t.datetime "updated_at",         null: false
    t.text     "description"
    t.boolean  "approved"
    t.integer  "user_id"
    t.string   "photo_file_name"
    t.string   "photo_content_type"
    t.integer  "photo_file_size"
    t.datetime "photo_updated_at"
  end

  create_table "location_types", force: true do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string   "name"
  end

  create_table "locations", force: true do |t|
    t.string   "name"
    t.string   "street"
    t.string   "city"
    t.string   "state"
    t.string   "zip"
    t.string   "phone"
    t.decimal  "lat",              precision: 18, scale: 12
    t.decimal  "lon",              precision: 18, scale: 12
    t.string   "website"
    t.datetime "created_at",                                 null: false
    t.datetime "updated_at",                                 null: false
    t.integer  "zone_id"
    t.integer  "region_id"
    t.integer  "location_type_id"
    t.string   "description"
    t.integer  "operator_id"
  end

  create_table "machine_groups", force: true do |t|
    t.string   "name",       null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "machine_score_xrefs", force: true do |t|
    t.integer  "location_machine_xref_id"
    t.integer  "score",                    limit: 8
    t.datetime "created_at",                         null: false
    t.datetime "updated_at",                         null: false
    t.integer  "rank"
    t.string   "ip"
    t.integer  "user_id"
    t.string   "initials"
  end

  add_index "machine_score_xrefs", ["location_machine_xref_id"], name: "index_machine_score_xrefs_on_location_machine_xref_id", using: :btree

  create_table "machines", force: true do |t|
    t.string   "name"
    t.boolean  "is_active"
    t.datetime "created_at",       null: false
    t.datetime "updated_at",       null: false
    t.string   "ipdb_link"
    t.integer  "year"
    t.string   "manufacturer"
    t.integer  "machine_group_id"
  end

  create_table "operators", force: true do |t|
    t.string   "name"
    t.integer  "region_id"
    t.string   "email"
    t.string   "website"
    t.string   "phone"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "rails_admin_histories", force: true do |t|
    t.string   "message"
    t.string   "username"
    t.integer  "item"
    t.string   "table"
    t.integer  "month",      limit: 2
    t.integer  "year",       limit: 8
    t.datetime "created_at",           null: false
    t.datetime "updated_at",           null: false
  end

  add_index "rails_admin_histories", ["item", "table", "month", "year"], name: "index_histories_on_item_and_table_and_month_and_year", using: :btree

  create_table "region_link_xrefs", force: true do |t|
    t.string  "name"
    t.string  "url"
    t.string  "description"
    t.string  "category"
    t.integer "region_id"
    t.integer "sort_order"
  end

  create_table "regions", force: true do |t|
    t.string   "name"
    t.datetime "created_at",                                             null: false
    t.datetime "updated_at",                                             null: false
    t.string   "full_name"
    t.string   "motd"
    t.decimal  "lat",                          precision: 18, scale: 12
    t.decimal  "lon",                          precision: 18, scale: 12
    t.integer  "n_search_no"
    t.string   "default_search_type"
    t.boolean  "should_email_machine_removal"
  end

  create_table "users", force: true do |t|
    t.string   "email"
    t.string   "encrypted_password"
    t.integer  "sign_in_count"
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.datetime "created_at",               null: false
    t.datetime "updated_at",               null: false
    t.integer  "region_id"
    t.string   "initials"
    t.datetime "reset_password_sent_at"
    t.boolean  "is_machine_admin"
    t.boolean  "is_primary_email_contact"
    t.boolean  "is_super_admin"
  end

  add_index "users", ["email"], name: "index_users_on_email", unique: true, using: :btree

  create_table "zones", force: true do |t|
    t.string   "name"
    t.integer  "region_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string   "short_name"
    t.boolean  "is_primary"
  end

end
