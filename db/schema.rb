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

ActiveRecord::Schema[8.1].define(version: 2025_11_23_113546) do
  create_table "email_accounts", force: :cascade do |t|
    t.text "access_token"
    t.datetime "created_at", null: false
    t.string "email_address", null: false
    t.datetime "expires_at"
    t.string "provider", null: false
    t.string "provider_account_id", null: false
    t.text "refresh_token"
    t.string "scope"
    t.string "status"
    t.string "token_type"
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["provider", "provider_account_id"], name: "index_email_accounts_on_provider_and_provider_account_id", unique: true
    t.index ["user_id"], name: "index_email_accounts_on_user_id"
  end

  create_table "emails", force: :cascade do |t|
    t.text "body_html"
    t.text "body_text"
    t.datetime "created_at", null: false
    t.integer "email_account_id", null: false
    t.string "from_address"
    t.text "headers"
    t.string "message_id"
    t.boolean "processed"
    t.datetime "sent_at"
    t.text "snippet"
    t.string "subject"
    t.string "thread_id"
    t.string "to_address"
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["email_account_id"], name: "index_emails_on_email_account_id"
    t.index ["user_id"], name: "index_emails_on_user_id"
  end

  create_table "sessions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "ip_address"
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.integer "user_id", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "transactions", force: :cascade do |t|
    t.integer "amount_cents"
    t.string "category"
    t.datetime "created_at", null: false
    t.string "currency"
    t.integer "email_id", null: false
    t.string "merchant"
    t.text "metadata"
    t.text "notes"
    t.string "status"
    t.date "transaction_date"
    t.integer "transaction_type", default: 0, null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["email_id"], name: "index_transactions_on_email_id"
    t.index ["transaction_type"], name: "index_transactions_on_transaction_type"
    t.index ["user_id"], name: "index_transactions_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email_address", null: false
    t.string "password_digest", null: false
    t.datetime "updated_at", null: false
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
  end

  add_foreign_key "email_accounts", "users"
  add_foreign_key "emails", "email_accounts"
  add_foreign_key "emails", "users"
  add_foreign_key "sessions", "users"
  add_foreign_key "transactions", "emails"
  add_foreign_key "transactions", "users"
end
