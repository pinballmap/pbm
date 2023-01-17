# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2023_01_17_174254) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_stat_statements"
  enable_extension "plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum", null: false
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
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
    t.string "icon"
    t.string "library"
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
    t.text "description"
    t.integer "operator_id"
    t.date "date_last_updated"
    t.integer "last_updated_by_user_id"
    t.boolean "is_stern_army"
    t.text "country"
    t.index ["is_stern_army"], name: "index_locations_on_is_stern_army"
    t.index ["last_updated_by_user_id"], name: "index_locations_on_last_updated_by_user_id"
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
    t.index ["user_id"], name: "index_machine_conditions_on_user_id"
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
    t.text "opdb_id"
    t.text "opdb_img"
    t.integer "opdb_img_height"
    t.integer "opdb_img_width"
    t.string "type"
    t.string "display"
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
    t.text "message"
    t.text "username"
    t.integer "item"
    t.text "table"
    t.integer "month"
    t.bigint "year"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["item", "table", "month", "year"], name: "index_histories_on_item_and_table_and_month_and_year"
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
    t.float "effective_radius", default: 200.0
  end

  create_table "ssw_lpx_backup", id: false, force: :cascade do |t|
    t.integer "id"
    t.integer "location_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text "description"
    t.integer "user_id"
    t.string "photo_file_name", limit: 255
    t.string "photo_content_type", limit: 255
    t.integer "photo_file_size"
    t.datetime "photo_updated_at"
  end

  create_table "ssw_tmp_weird_empty_lmxes", id: false, force: :cascade do |t|
    t.integer "id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "location_id"
    t.integer "machine_id"
    t.text "condition"
    t.date "condition_date"
    t.string "ip", limit: 255
    t.integer "user_id"
    t.integer "machine_score_xrefs_count"
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
    t.text "country"
  end

  create_table "user_fave_locations", force: :cascade do |t|
    t.integer "user_id"
    t.integer "location_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
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
    t.string "email", limit: 255, default: "", null: false
    t.string "encrypted_password", limit: 128, default: "", null: false
    t.string "password_salt", limit: 255, default: "", null: false
    t.string "reset_password_token", limit: 255
    t.string "remember_token", limit: 255
    t.datetime "remember_created_at"
    t.integer "sign_in_count", default: 0
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
    t.string "security_test"
    t.index ["authentication_token"], name: "index_users_on_authentication_token", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["region_id"], name: "index_users_on_region_id"
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
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

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
end
