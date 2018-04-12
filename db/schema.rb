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

ActiveRecord::Schema.define(version: 20180412042101) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "banned_ips", id: :serial, force: :cascade do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "ip_address", limit: 255
  end

  create_table "events", id: :serial, force: :cascade do |t|
    t.integer "region_id"
    t.string "name", limit: 255
    t.text "long_desc"
    t.string "external_link", limit: 255
    t.integer "category_no"
    t.date "start_date"
    t.date "end_date"
    t.integer "location_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "category", limit: 255
    t.string "external_location_name", limit: 255
    t.integer "ifpa_calendar_id"
    t.integer "ifpa_tournament_id"
    t.index ["ifpa_calendar_id"], name: "index_events_on_ifpa_calendar_id"
    t.index ["ifpa_tournament_id"], name: "index_events_on_ifpa_tournament_id"
    t.index ["location_id"], name: "index_events_on_location_id"
    t.index ["region_id"], name: "index_events_on_region_id"
  end

  create_table "location_machine_xrefs", id: :serial, force: :cascade do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "location_id"
    t.integer "machine_id"
    t.text "condition"
    t.date "condition_date"
    t.string "ip", limit: 255
    t.integer "user_id"
    t.integer "machine_score_xrefs_count"
    t.index ["location_id"], name: "index_location_machine_xrefs_on_location_id"
    t.index ["machine_id"], name: "index_location_machine_xrefs_on_machine_id"
    t.index ["user_id"], name: "index_location_machine_xrefs_on_user_id"
  end

  create_table "location_picture_xrefs", id: :serial, force: :cascade do |t|
    t.integer "location_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text "description"
    t.boolean "approved"
    t.integer "user_id"
    t.string "photo_file_name", limit: 255
    t.string "photo_content_type", limit: 255
    t.integer "photo_file_size"
    t.datetime "photo_updated_at"
    t.index ["location_id"], name: "index_location_picture_xrefs_on_location_id"
    t.index ["user_id"], name: "index_location_picture_xrefs_on_user_id"
  end

  create_table "location_types", id: :serial, force: :cascade do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "name", limit: 255
  end

  create_table "locations", id: :serial, force: :cascade do |t|
    t.string "name", limit: 255
    t.string "street", limit: 255
    t.string "city", limit: 255
    t.string "state", limit: 255
    t.string "zip", limit: 255
    t.string "phone", limit: 255
    t.decimal "lat", precision: 18, scale: 12
    t.decimal "lon", precision: 18, scale: 12
    t.string "website", limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "zone_id"
    t.integer "region_id"
    t.integer "location_type_id"
    t.string "description", limit: 255
    t.integer "operator_id"
    t.date "date_last_updated"
    t.integer "last_updated_by_user_id"
    t.boolean "is_stern_army"
    t.index ["location_type_id"], name: "index_locations_on_location_type_id"
    t.index ["operator_id"], name: "index_locations_on_operator_id"
    t.index ["region_id"], name: "index_locations_on_region_id"
    t.index ["zone_id"], name: "index_locations_on_zone_id"
  end

  create_table "machine_conditions", id: :serial, force: :cascade do |t|
    t.text "comment"
    t.integer "location_machine_xref_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "user_id"
    t.index ["location_machine_xref_id"], name: "index_machine_conditions_on_location_machine_xref_id"
  end

  create_table "machine_groups", id: :serial, force: :cascade do |t|
    t.string "name", limit: 255, null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "machine_score_xrefs", id: :serial, force: :cascade do |t|
    t.integer "location_machine_xref_id"
    t.bigint "score"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "ip", limit: 255
    t.integer "user_id"
    t.string "rank", limit: 255
    t.index ["location_machine_xref_id"], name: "index_machine_score_xrefs_on_location_machine_xref_id"
    t.index ["user_id"], name: "index_machine_score_xrefs_on_user_id"
  end

  create_table "machines", id: :serial, force: :cascade do |t|
    t.string "name", limit: 255
    t.boolean "is_active"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "ipdb_link", limit: 255
    t.integer "year"
    t.string "manufacturer", limit: 255
    t.integer "machine_group_id"
    t.integer "ipdb_id"
    t.index ["machine_group_id"], name: "index_machines_on_machine_group_id"
  end

  create_table "operators", id: :serial, force: :cascade do |t|
    t.string "name", limit: 255
    t.integer "region_id"
    t.string "email", limit: 255
    t.string "website", limit: 255
    t.string "phone", limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["region_id"], name: "index_operators_on_region_id"
  end

  create_table "rails_admin_histories", id: :serial, force: :cascade do |t|
    t.string "message", limit: 255
    t.string "username", limit: 255
    t.integer "item"
    t.string "table", limit: 255
    t.integer "month", limit: 2
    t.bigint "year"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["item", "table", "month", "year"], name: "index_rails_admin_histories"
  end

  create_table "region_link_xrefs", id: :serial, force: :cascade do |t|
    t.string "name", limit: 255
    t.string "url", limit: 255
    t.string "description", limit: 255
    t.string "category", limit: 255
    t.integer "region_id"
    t.integer "sort_order"
    t.index ["region_id"], name: "index_region_link_xrefs_on_region_id"
  end

  create_table "regions", id: :serial, force: :cascade do |t|
    t.string "name", limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "full_name", limit: 255
    t.string "motd", limit: 255, default: "To help keep Pinball Map running, consider a donation! https://pinballmap.com/donate"
    t.decimal "lat", precision: 18, scale: 12
    t.decimal "lon", precision: 18, scale: 12
    t.integer "n_search_no"
    t.string "default_search_type", limit: 255
    t.boolean "should_email_machine_removal"
    t.boolean "should_auto_delete_empty_locations"
    t.boolean "send_digest_comment_emails"
    t.boolean "send_digest_removal_emails"
    t.text "state"
  end

  create_table "suggested_locations", id: :serial, force: :cascade do |t|
    t.text "name"
    t.text "street"
    t.text "city"
    t.text "state"
    t.text "zip"
    t.text "phone"
    t.text "website"
    t.integer "location_type_id"
    t.integer "operator_id"
    t.integer "region_id"
    t.text "comments"
    t.text "machines"
    t.text "user_inputted_address"
    t.decimal "lat", precision: 18, scale: 12
    t.decimal "lon", precision: 18, scale: 12
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "zone_id"
  end

  create_table "user_submissions", id: :serial, force: :cascade do |t|
    t.text "submission_type"
    t.text "submission"
    t.integer "region_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "user_id"
    t.integer "location_id"
    t.integer "machine_id"
    t.index ["region_id"], name: "index_user_submissions_on_region_id"
  end

  create_table "users", id: :serial, force: :cascade do |t|
    t.string "email", limit: 255
    t.string "encrypted_password", limit: 255
    t.integer "sign_in_count"
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string "current_sign_in_ip", limit: 255
    t.string "last_sign_in_ip", limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "region_id"
    t.string "initials", limit: 255
    t.datetime "reset_password_sent_at"
    t.boolean "is_machine_admin"
    t.boolean "is_primary_email_contact"
    t.boolean "is_super_admin"
    t.text "username"
    t.string "confirmation_token", limit: 255
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.boolean "is_disabled"
    t.string "authentication_token", limit: 30
    t.index ["authentication_token"], name: "index_users_on_authentication_token", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["region_id"], name: "index_users_on_region_id"
    t.index ["username"], name: "index_users_on_username", unique: true
  end

  create_table "zones", id: :serial, force: :cascade do |t|
    t.string "name", limit: 255
    t.integer "region_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "short_name", limit: 255
    t.boolean "is_primary"
    t.index ["region_id"], name: "index_zones_on_region_id"
  end

end
