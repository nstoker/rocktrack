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

ActiveRecord::Schema[8.1].define(version: 2025_12_07_165014) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "account_users", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.datetime "created_at", null: false
    t.integer "role", default: 0, null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["account_id"], name: "index_account_users_on_account_id"
    t.index ["user_id"], name: "index_account_users_on_user_id"
  end

  create_table "accounts", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.boolean "gifted", default: false
    t.string "name"
    t.bigint "owner_id"
    t.string "processor_customer_id"
    t.string "slug"
    t.integer "subscription_status", default: 0
    t.datetime "updated_at", null: false
    t.index ["owner_id"], name: "index_accounts_on_owner_id"
  end

  create_table "action_text_rich_texts", force: :cascade do |t|
    t.text "body"
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.datetime "updated_at", null: false
    t.index ["record_type", "record_id", "name"], name: "index_action_text_rich_texts_uniqueness", unique: true
  end

  create_table "active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "commerce_benefits", force: :cascade do |t|
    t.boolean "active", default: true
    t.text "benefit_text"
    t.datetime "created_at", null: false
    t.string "name"
    t.text "tooltip"
    t.datetime "updated_at", null: false
  end

  create_table "commerce_payment_methods", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.integer "brand"
    t.datetime "created_at", null: false
    t.boolean "default", default: false
    t.integer "expiration_month"
    t.integer "expiration_year"
    t.string "last4"
    t.string "processor_customer_id"
    t.string "processor_payment_method_id"
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_commerce_payment_methods_on_account_id"
  end

  create_table "commerce_payments", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.integer "amount"
    t.datetime "created_at", null: false
    t.string "currency"
    t.bigint "payment_method_id"
    t.string "processor_customer_id"
    t.string "processor_invoice_id"
    t.string "processor_payment_id"
    t.bigint "purchase_id"
    t.string "resolve_token"
    t.integer "status", default: 0
    t.bigint "subscription_id"
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_commerce_payments_on_account_id"
    t.index ["payment_method_id"], name: "index_commerce_payments_on_payment_method_id"
    t.index ["purchase_id"], name: "index_commerce_payments_on_purchase_id"
    t.index ["subscription_id"], name: "index_commerce_payments_on_subscription_id"
  end

  create_table "commerce_plan_benefits", force: :cascade do |t|
    t.bigint "benefit_id", null: false
    t.datetime "created_at", null: false
    t.bigint "plan_id", null: false
    t.integer "position", default: 1
    t.datetime "updated_at", null: false
    t.index ["benefit_id"], name: "index_commerce_plan_benefits_on_benefit_id"
    t.index ["plan_id"], name: "index_commerce_plan_benefits_on_plan_id"
  end

  create_table "commerce_plans", force: :cascade do |t|
    t.boolean "active", default: true
    t.text "benefits_note"
    t.string "button_change_to_plan_label"
    t.string "button_current_label"
    t.string "button_purchase_label"
    t.string "button_support_text"
    t.string "button_url"
    t.datetime "created_at", null: false
    t.string "display_name"
    t.string "highlight_text"
    t.string "name"
    t.integer "position", default: 1
    t.string "price_a_alt_amount"
    t.string "price_a_append_text"
    t.bigint "price_a_id"
    t.string "price_a_note"
    t.string "price_b_alt_amount"
    t.string "price_b_append_text"
    t.bigint "price_b_id"
    t.string "price_b_note"
    t.text "short_description"
    t.datetime "updated_at", null: false
    t.index ["price_a_id"], name: "index_commerce_plans_on_price_a_id"
    t.index ["price_b_id"], name: "index_commerce_plans_on_price_b_id"
  end

  create_table "commerce_prices", force: :cascade do |t|
    t.integer "amount"
    t.datetime "created_at", null: false
    t.string "name"
    t.string "processor_price_id"
    t.bigint "product_id", null: false
    t.boolean "recurring", default: false
    t.integer "recurring_interval", default: 0
    t.string "slug"
    t.integer "trial_days", default: 0
    t.datetime "updated_at", null: false
    t.index ["product_id"], name: "index_commerce_prices_on_product_id"
  end

  create_table "commerce_products", force: :cascade do |t|
    t.boolean "active", default: true
    t.datetime "created_at", null: false
    t.string "name"
    t.string "processor_product_id"
    t.string "slug"
    t.datetime "updated_at", null: false
  end

  create_table "commerce_purchases", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.datetime "created_at", null: false
    t.bigint "first_payment_id"
    t.bigint "payment_method_id"
    t.bigint "price_id", null: false
    t.string "processor_customer_id"
    t.bigint "product_id", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_commerce_purchases_on_account_id"
    t.index ["first_payment_id"], name: "index_commerce_purchases_on_first_payment_id"
    t.index ["payment_method_id"], name: "index_commerce_purchases_on_payment_method_id"
    t.index ["price_id"], name: "index_commerce_purchases_on_price_id"
    t.index ["product_id"], name: "index_commerce_purchases_on_product_id"
  end

  create_table "commerce_subscriptions", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.datetime "cancellation_date"
    t.text "cancellation_reason"
    t.datetime "created_at", null: false
    t.datetime "current_period_end"
    t.bigint "payment_method_id"
    t.bigint "price_id", null: false
    t.string "processor_customer_id"
    t.string "processor_subscription_id"
    t.bigint "product_id", null: false
    t.bigint "purchase_id", null: false
    t.integer "status", default: 0
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_commerce_subscriptions_on_account_id"
    t.index ["payment_method_id"], name: "index_commerce_subscriptions_on_payment_method_id"
    t.index ["price_id"], name: "index_commerce_subscriptions_on_price_id"
    t.index ["product_id"], name: "index_commerce_subscriptions_on_product_id"
    t.index ["purchase_id"], name: "index_commerce_subscriptions_on_purchase_id"
  end

  create_table "invitations", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.datetime "created_at", null: false
    t.bigint "created_by_user_id", null: false
    t.string "email", null: false
    t.integer "role", default: 0, null: false
    t.integer "status", default: 0, null: false
    t.string "token", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_invitations_on_account_id"
    t.index ["created_by_user_id"], name: "index_invitations_on_created_by_user_id"
  end

  create_table "sessions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "ip_address"
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.bigint "user_id", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.boolean "admin", default: false
    t.datetime "created_at", null: false
    t.string "email_address", null: false
    t.string "first_name"
    t.string "last_name"
    t.string "password_digest", null: false
    t.string "timezone", default: "UTC"
    t.datetime "updated_at", null: false
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
  end

  add_foreign_key "account_users", "accounts"
  add_foreign_key "account_users", "users"
  add_foreign_key "accounts", "users", column: "owner_id"
  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "commerce_payment_methods", "accounts"
  add_foreign_key "commerce_payments", "accounts"
  add_foreign_key "commerce_payments", "commerce_payment_methods", column: "payment_method_id"
  add_foreign_key "commerce_payments", "commerce_purchases", column: "purchase_id"
  add_foreign_key "commerce_payments", "commerce_subscriptions", column: "subscription_id"
  add_foreign_key "commerce_plan_benefits", "commerce_benefits", column: "benefit_id"
  add_foreign_key "commerce_plan_benefits", "commerce_plans", column: "plan_id"
  add_foreign_key "commerce_plans", "commerce_prices", column: "price_a_id"
  add_foreign_key "commerce_plans", "commerce_prices", column: "price_b_id"
  add_foreign_key "commerce_prices", "commerce_products", column: "product_id"
  add_foreign_key "commerce_purchases", "accounts"
  add_foreign_key "commerce_purchases", "commerce_payment_methods", column: "payment_method_id"
  add_foreign_key "commerce_purchases", "commerce_payments", column: "first_payment_id"
  add_foreign_key "commerce_purchases", "commerce_prices", column: "price_id"
  add_foreign_key "commerce_purchases", "commerce_products", column: "product_id"
  add_foreign_key "commerce_subscriptions", "accounts"
  add_foreign_key "commerce_subscriptions", "commerce_payment_methods", column: "payment_method_id"
  add_foreign_key "commerce_subscriptions", "commerce_prices", column: "price_id"
  add_foreign_key "commerce_subscriptions", "commerce_products", column: "product_id"
  add_foreign_key "commerce_subscriptions", "commerce_purchases", column: "purchase_id"
  add_foreign_key "invitations", "accounts"
  add_foreign_key "invitations", "users", column: "created_by_user_id"
  add_foreign_key "sessions", "users"
end
