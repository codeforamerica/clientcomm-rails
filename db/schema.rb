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

ActiveRecord::Schema.define(version: 20180105010123) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "active_admin_comments", force: :cascade do |t|
    t.string "namespace"
    t.text "body"
    t.string "resource_type"
    t.bigint "resource_id"
    t.string "author_type"
    t.bigint "author_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["author_type", "author_id"], name: "index_active_admin_comments_on_author_type_and_author_id"
    t.index ["namespace"], name: "index_active_admin_comments_on_namespace"
    t.index ["resource_type", "resource_id"], name: "index_active_admin_comments_on_resource_type_and_resource_id"
  end

  create_table "admin_users", id: :serial, force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.inet "current_sign_in_ip"
    t.inet "last_sign_in_ip"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_admin_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_admin_users_on_reset_password_token", unique: true
  end

  create_table "attachments", force: :cascade do |t|
    t.bigint "message_id", null: false
    t.string "media_file_name"
    t.string "media_content_type"
    t.integer "media_file_size"
    t.datetime "media_updated_at"
    t.index ["message_id"], name: "index_attachments_on_message_id"
  end

  create_table "client_statuses", force: :cascade do |t|
    t.string "name", null: false
    t.integer "followup_date", null: false
  end

  create_table "clients", id: :serial, force: :cascade do |t|
    t.string "first_name"
    t.string "last_name"
    t.string "phone_number"
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id"
    t.text "notes"
    t.datetime "last_contacted_at"
    t.boolean "has_unread_messages", default: false, null: false
    t.boolean "has_message_error", default: false, null: false
    t.bigint "client_status_id"
    t.index ["client_status_id"], name: "index_clients_on_client_status_id"
    t.index ["phone_number"], name: "index_clients_on_phone_number", unique: true
    t.index ["user_id"], name: "index_clients_on_user_id"
  end

  create_table "delayed_jobs", id: :serial, force: :cascade do |t|
    t.integer "priority", default: 0, null: false
    t.integer "attempts", default: 0, null: false
    t.text "handler", null: false
    t.text "last_error"
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string "locked_by"
    t.string "queue"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["priority", "run_at"], name: "delayed_jobs_priority"
  end

  create_table "departments", force: :cascade do |t|
    t.string "name"
    t.string "phone_number"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.index ["user_id"], name: "index_departments_on_user_id"
  end

  create_table "feature_flags", force: :cascade do |t|
    t.string "flag"
    t.boolean "enabled", null: false
  end

  create_table "messages", id: :serial, force: :cascade do |t|
    t.integer "client_id"
    t.integer "user_id"
    t.string "body", default: ""
    t.string "number_from", null: false
    t.string "number_to", null: false
    t.boolean "inbound", default: false, null: false
    t.string "twilio_sid"
    t.string "twilio_status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "read", default: false
    t.datetime "send_at", null: false
    t.integer "lock_version", default: 0
    t.boolean "sent", default: false
    t.index ["client_id"], name: "index_messages_on_client_id"
    t.index ["twilio_sid"], name: "index_messages_on_twilio_sid"
    t.index ["user_id"], name: "index_messages_on_user_id"
  end

  create_table "reporting_relationships", force: :cascade do |t|
    t.bigint "user_id"
    t.bigint "client_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "active", default: true, null: false
    t.text "notes"
    t.datetime "last_contacted_at"
    t.boolean "has_unread_messages", default: false, null: false
    t.boolean "has_message_error", default: false, null: false
    t.bigint "client_status_id"
    t.index ["client_id"], name: "index_reporting_relationships_on_client_id"
    t.index ["client_status_id"], name: "index_reporting_relationships_on_client_status_id"
    t.index ["user_id"], name: "index_reporting_relationships_on_user_id"
  end

  create_table "survey_questions", force: :cascade do |t|
    t.text "text"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "survey_responses", force: :cascade do |t|
    t.text "text"
    t.bigint "survey_question_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["survey_question_id"], name: "index_survey_responses_on_survey_question_id"
  end

  create_table "surveys", force: :cascade do |t|
    t.bigint "client_id"
    t.bigint "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["client_id"], name: "index_surveys_on_client_id"
    t.index ["user_id"], name: "index_surveys_on_user_id"
  end

  create_table "templates", force: :cascade do |t|
    t.string "title"
    t.text "body"
    t.bigint "user_id"
    t.index ["user_id"], name: "index_templates_on_user_id"
  end

  create_table "users", id: :serial, force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.inet "current_sign_in_ip"
    t.inet "last_sign_in_ip"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "full_name", null: false
    t.boolean "message_notification_emails", default: true
    t.boolean "active", default: true, null: false
    t.string "phone_number"
    t.bigint "department_id"
    t.index ["department_id"], name: "index_users_on_department_id"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "attachments", "messages"
  add_foreign_key "clients", "client_statuses"
  add_foreign_key "clients", "users"
  add_foreign_key "departments", "users"
  add_foreign_key "messages", "clients"
  add_foreign_key "messages", "users"
  add_foreign_key "reporting_relationships", "client_statuses"
  add_foreign_key "reporting_relationships", "clients"
  add_foreign_key "reporting_relationships", "users"
  add_foreign_key "survey_responses", "survey_questions"
  add_foreign_key "surveys", "clients"
  add_foreign_key "surveys", "users"
  add_foreign_key "templates", "users"
  add_foreign_key "users", "departments"
end
