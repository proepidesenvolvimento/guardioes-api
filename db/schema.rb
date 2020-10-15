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

ActiveRecord::Schema.define(version: 2020_10_15_172421) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "admins", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "first_name", default: "", null: false
    t.string "last_name", default: "", null: false
    t.boolean "is_god", default: false, null: false
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
    t.bigint "app_id"
    t.bigint "permission_id"
    t.index ["app_id"], name: "index_admins_on_app_id"
    t.index ["email"], name: "index_admins_on_email", unique: true
    t.index ["permission_id"], name: "index_admins_on_permission_id"
    t.index ["reset_password_token"], name: "index_admins_on_reset_password_token", unique: true
  end

  create_table "apps", force: :cascade do |t|
    t.string "app_name", default: "", null: false
    t.string "owner_country", default: "", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "contents", force: :cascade do |t|
    t.string "title", default: "", null: false
    t.text "body", default: "", null: false
    t.string "content_type", default: "", null: false
    t.bigint "app_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "source_link"
    t.string "icon"
    t.index ["app_id"], name: "index_contents_on_app_id"
  end

  create_table "crono_jobs", force: :cascade do |t|
    t.string "job_id", null: false
    t.text "log"
    t.datetime "last_performed_at"
    t.boolean "healthy"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["job_id"], name: "index_crono_jobs_on_job_id", unique: true
  end

  create_table "group_managers", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "name"
    t.bigint "app_id"
    t.string "group_name"
    t.string "twitter"
    t.boolean "require_id"
    t.integer "id_code_length"
    t.string "vigilance_email"
    t.bigint "permission_id"
    t.index ["app_id"], name: "index_group_managers_on_app_id"
    t.index ["email"], name: "index_group_managers_on_email", unique: true
    t.index ["permission_id"], name: "index_group_managers_on_permission_id"
    t.index ["reset_password_token"], name: "index_group_managers_on_reset_password_token", unique: true
  end

  create_table "groups", force: :cascade do |t|
    t.string "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at"
    t.bigint "parent_id"
    t.string "children_label"
    t.string "code"
    t.string "address"
    t.string "cep"
    t.string "phone"
    t.string "email"
    t.integer "group_manager_id"
    t.index ["deleted_at"], name: "index_groups_on_deleted_at"
    t.index ["parent_id"], name: "index_groups_on_parent_id"
  end

  create_table "households", force: :cascade do |t|
    t.string "description"
    t.date "birthdate"
    t.string "country"
    t.string "gender"
    t.string "race"
    t.string "kinship"
    t.bigint "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at"
    t.string "picture"
    t.bigint "school_unit_id"
    t.string "identification_code"
    t.boolean "risk_group"
    t.integer "group_id"
    t.index ["deleted_at"], name: "index_households_on_deleted_at"
    t.index ["school_unit_id"], name: "index_households_on_school_unit_id"
    t.index ["user_id"], name: "index_households_on_user_id"
  end

  create_table "jwt_blacklist", force: :cascade do |t|
    t.string "jti", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["jti"], name: "index_jwt_blacklist_on_jti"
  end

  create_table "manager_group_permissions", force: :cascade do |t|
    t.bigint "group_manager_id"
    t.bigint "group_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["group_id"], name: "index_manager_group_permissions_on_group_id"
    t.index ["group_manager_id"], name: "index_manager_group_permissions_on_group_manager_id"
  end

  create_table "managers", force: :cascade do |t|
    t.string "name"
    t.string "password"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.bigint "app_id"
    t.bigint "permission_id"
    t.index ["app_id"], name: "index_managers_on_app_id"
    t.index ["email"], name: "index_managers_on_email", unique: true
    t.index ["permission_id"], name: "index_managers_on_permission_id"
    t.index ["reset_password_token"], name: "index_managers_on_reset_password_token", unique: true
  end

  create_table "messages", force: :cascade do |t|
    t.string "title"
    t.text "warning_message"
    t.text "go_to_hospital_message"
    t.bigint "syndrome_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "symptom_id"
    t.string "feedback_message"
    t.index ["symptom_id"], name: "index_messages_on_symptom_id"
    t.index ["syndrome_id"], name: "index_messages_on_syndrome_id"
  end

  create_table "permissions", force: :cascade do |t|
    t.text "models_create"
    t.text "models_read"
    t.text "models_update"
    t.text "models_destroy"
    t.text "models_manage"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "pre_registers", force: :cascade do |t|
    t.string "cnpj"
    t.string "phone"
    t.string "organization_kind"
    t.string "state"
    t.string "company_name"
    t.bigint "app_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "email"
    t.index ["app_id"], name: "index_pre_registers_on_app_id"
  end

  create_table "public_hospitals", force: :cascade do |t|
    t.string "description"
    t.float "latitude"
    t.float "longitude"
    t.string "kind"
    t.string "phone"
    t.text "details"
    t.bigint "app_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["app_id"], name: "index_public_hospitals_on_app_id"
  end

  create_table "rumors", force: :cascade do |t|
    t.string "title"
    t.text "description"
    t.integer "confirmed_cases"
    t.integer "confirmed_deaths"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "school_units", force: :cascade do |t|
    t.string "code"
    t.string "description"
    t.string "address"
    t.string "cep"
    t.string "phone"
    t.string "fax"
    t.string "email"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "category"
    t.string "zone"
    t.string "level"
    t.string "city"
    t.string "state"
  end

  create_table "surveys", force: :cascade do |t|
    t.bigint "user_id"
    t.bigint "household_id"
    t.float "latitude"
    t.float "longitude"
    t.date "bad_since"
    t.text "symptom"
    t.string "street"
    t.string "city"
    t.string "state"
    t.string "country"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at"
    t.string "traveled_to"
    t.string "contact_with_symptom"
    t.boolean "went_to_hospital"
    t.index ["deleted_at"], name: "index_surveys_on_deleted_at"
    t.index ["household_id"], name: "index_surveys_on_household_id"
    t.index ["user_id"], name: "index_surveys_on_user_id"
  end

  create_table "symptoms", force: :cascade do |t|
    t.string "description"
    t.string "code"
    t.integer "priority"
    t.text "details"
    t.bigint "app_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "syndrome_id"
    t.bigint "message_id"
    t.index ["app_id"], name: "index_symptoms_on_app_id"
    t.index ["message_id"], name: "index_symptoms_on_message_id"
    t.index ["syndrome_id"], name: "index_symptoms_on_syndrome_id"
  end

  create_table "syndrome_symptom_percentages", force: :cascade do |t|
    t.float "percentage"
    t.bigint "symptom_id"
    t.bigint "syndrome_id"
    t.index ["symptom_id"], name: "index_syndrome_symptom_percentages_on_symptom_id"
    t.index ["syndrome_id"], name: "index_syndrome_symptom_percentages_on_syndrome_id"
  end

  create_table "syndromes", force: :cascade do |t|
    t.string "description"
    t.string "details"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "message_id"
    t.index ["message_id"], name: "index_syndromes_on_message_id"
  end

  create_table "twitter_apis", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "twitterdata"
    t.string "handle"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.string "user_name"
    t.datetime "birthdate"
    t.string "country"
    t.string "gender"
    t.string "race"
    t.boolean "is_professional", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "app_id"
    t.datetime "deleted_at"
    t.string "picture"
    t.string "identification_code"
    t.string "state"
    t.string "city"
    t.bigint "group_id"
    t.boolean "risk_group"
    t.string "aux_code"
    t.bigint "school_unit_id"
    t.integer "policy_version", default: 1, null: false
    t.string "phone"
    t.boolean "is_vigilance"
    t.integer "streak", default: 0
    t.index ["app_id"], name: "index_users_on_app_id"
    t.index ["deleted_at"], name: "index_users_on_deleted_at"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["group_id"], name: "index_users_on_group_id"
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["school_unit_id"], name: "index_users_on_school_unit_id"
  end

  add_foreign_key "admins", "apps"
  add_foreign_key "admins", "permissions"
  add_foreign_key "contents", "apps"
  add_foreign_key "group_managers", "apps"
  add_foreign_key "group_managers", "permissions"
  add_foreign_key "households", "school_units"
  add_foreign_key "households", "users"
  add_foreign_key "manager_group_permissions", "group_managers"
  add_foreign_key "manager_group_permissions", "groups"
  add_foreign_key "managers", "apps"
  add_foreign_key "managers", "permissions"
  add_foreign_key "messages", "symptoms"
  add_foreign_key "messages", "syndromes"
  add_foreign_key "pre_registers", "apps"
  add_foreign_key "public_hospitals", "apps"
  add_foreign_key "surveys", "households"
  add_foreign_key "surveys", "users"
  add_foreign_key "symptoms", "apps"
  add_foreign_key "symptoms", "messages"
  add_foreign_key "symptoms", "syndromes"
  add_foreign_key "syndrome_symptom_percentages", "symptoms"
  add_foreign_key "syndrome_symptom_percentages", "syndromes"
  add_foreign_key "syndromes", "messages"
  add_foreign_key "users", "apps"
  add_foreign_key "users", "groups"
  add_foreign_key "users", "school_units"
end
