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

ActiveRecord::Schema[7.0].define(version: 2024_12_03_180109) do
  # These are extensions that must be enabled in order to support this database
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
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "contacts", force: :cascade do |t|
    t.text "key", null: false
    t.text "value"
    t.text "value_type", default: "text", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_contacts_on_key", unique: true
  end

  create_table "holidays", force: :cascade do |t|
    t.datetime "from_timestamp", precision: nil, null: false, comment: "From this moment on, the holiday is considered active"
    t.datetime "to_timestamp", precision: nil, comment: "If present, the holiday is considered active until this moment"
    t.time "weekly_from", comment: "If present, the holiday is considered active until 'weekly_to', but only after from_timestamp."
    t.time "weekly_to"
    t.integer "weekday", comment: "If present, the holiday is considered active only on this weekday."
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "image_to_records", force: :cascade do |t|
    t.bigint "image_id", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.integer "position", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["image_id"], name: "index_image_to_records_on_image_id"
    t.index ["position", "record_type", "record_id"], name: "index_image_to_records_on_position_and_record_and_image", unique: true
    t.index ["record_type", "record_id", "image_id"], name: "index_image_to_records_on_record_and_image", unique: true
    t.index ["record_type", "record_id"], name: "index_image_to_records_on_record"
  end

  create_table "images", force: :cascade do |t|
    t.text "filename", null: false
    t.text "status", null: false
    t.text "tag", comment: "Internal tag for image. A tag may be 'blur', 'thumbnail', ... May be nil when is original image."
    t.bigint "original_id"
    t.jsonb "other", default: {}, null: false
    t.text "key", comment: "Key for finding the Image for a certain purpose."
    t.string "member_id", comment: "External id of image."
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["filename"], name: "index_images_on_filename"
    t.index ["key"], name: "index_images_on_key", unique: true, where: "(key IS NOT NULL)"
    t.index ["original_id"], name: "index_images_on_original_id"
    t.index ["tag", "original_id"], name: "index_images_on_tag_and_original_id", unique: true, where: "(original_id IS NOT NULL)"
  end

  create_table "log_delivered_emails", force: :cascade do |t|
    t.string "record_type"
    t.bigint "record_id", comment: "Record this email is associated. Optional."
    t.text "text"
    t.text "html"
    t.text "subject"
    t.jsonb "headers"
    t.text "raw"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "controller_path"
    t.text "action_name"
    t.index ["record_type", "record_id"], name: "index_log_delivered_emails_on_record"
  end

  create_table "log_image_pixel_events", force: :cascade do |t|
    t.bigint "image_pixel_id", null: false
    t.jsonb "event_data", default: {}
    t.datetime "event_time", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["image_pixel_id"], name: "index_log_image_pixel_events_on_image_pixel_id"
  end

  create_table "log_image_pixels", force: :cascade do |t|
    t.bigint "image_id", null: false
    t.bigint "delivered_email_id", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false, comment: "Record this pixel is associated. Mandatory."
    t.text "event_type", null: false, comment: "What does this event mean. E.g. \"email_open\""
    t.text "secret", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["delivered_email_id"], name: "index_log_image_pixels_on_delivered_email_id"
    t.index ["image_id"], name: "index_log_image_pixels_on_image_id"
    t.index ["record_type", "record_id"], name: "index_log_image_pixels_on_record"
    t.index ["secret"], name: "index_log_image_pixels_on_secret", unique: true
  end

  create_table "log_model_changes", force: :cascade do |t|
    t.string "record_type", null: false
    t.bigint "record_id", null: false, comment: "Record that was changed."
    t.bigint "user_id", comment: "User who made the change."
    t.string "change_type", null: false, comment: "Type of change. One of: create, update, destroy."
    t.jsonb "record_changes", null: false, comment: "Changes made to the record. Format: { field_name: [old_value, new_value] }"
    t.string "changed_fields", comment: "List of fields that were changed. Format: [field_name1, field_name2, ...]", array: true
    t.integer "version", null: false, comment: "Version of the record. Incremented on each change."
    t.jsonb "other", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["change_type"], name: "index_log_model_changes_on_change_type"
    t.index ["record_type", "record_id"], name: "index_log_model_changes_on_record"
    t.index ["user_id"], name: "index_log_model_changes_on_user_id"
  end

  create_table "log_reservation_events", force: :cascade do |t|
    t.text "event_type"
    t.jsonb "payload"
    t.bigint "reservation_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["reservation_id"], name: "index_log_reservation_events_on_reservation_id"
  end

  create_table "menu_allergens", force: :cascade do |t|
    t.text "status", null: false
    t.jsonb "other", default: {}, null: false
    t.integer "member_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "menu_allergens_in_dishes", force: :cascade do |t|
    t.bigint "menu_dish_id", null: false
    t.bigint "menu_allergen_id", null: false
    t.integer "index", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["menu_allergen_id"], name: "index_menu_allergens_in_dishes_on_menu_allergen_id"
    t.index ["menu_dish_id", "index"], name: "index_menu_allergens_in_dishes_on_menu_dish_id_and_index", unique: true
    t.index ["menu_dish_id", "menu_allergen_id"], name: "index_menu_allergens_in_dishes_on_dish_and_allergen", unique: true
    t.index ["menu_dish_id"], name: "index_menu_allergens_in_dishes_on_menu_dish_id"
  end

  create_table "menu_categories", force: :cascade do |t|
    t.text "status", null: false
    t.integer "index", null: false
    t.text "secret", null: false
    t.text "secret_desc"
    t.jsonb "other", default: {}, null: false
    t.float "price"
    t.bigint "parent_id"
    t.bigint "menu_visibility_id"
    t.string "member_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "root_id", comment: "Root parent. Will be auto-calculated with before_validation"
    t.index ["index", "parent_id"], name: "index_menu_categories_on_index_and_parent_id", unique: true
    t.index ["menu_visibility_id"], name: "index_menu_categories_on_menu_visibility_id"
    t.index ["parent_id"], name: "index_menu_categories_on_parent_id"
    t.index ["root_id"], name: "index_menu_categories_on_root_id"
    t.index ["secret"], name: "index_menu_categories_on_secret"
    t.index ["secret_desc"], name: "index_menu_categories_on_secret_desc", unique: true, where: "(secret_desc IS NOT NULL)"
  end

  create_table "menu_dish_suggestions", force: :cascade do |t|
    t.bigint "dish_id", null: false
    t.bigint "suggestion_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["dish_id", "suggestion_id"], name: "index_menu_dish_suggestions_on_dish_id_and_suggestion_id", unique: true
    t.index ["dish_id"], name: "index_menu_dish_suggestions_on_dish_id"
    t.index ["suggestion_id"], name: "index_menu_dish_suggestions_on_suggestion_id"
    t.check_constraint "dish_id <> suggestion_id", name: "dish_id_not_equal_suggestion_id"
  end

  create_table "menu_dishes", force: :cascade do |t|
    t.text "status", null: false
    t.float "price", comment: "The price of the dish. Can be null or 0 some cases, for example when the dish is inside a category with a fixed price."
    t.jsonb "other", default: {}, null: false
    t.integer "member_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "menu_dishes_in_categories", force: :cascade do |t|
    t.bigint "menu_dish_id", null: false
    t.bigint "menu_category_id"
    t.integer "index", null: false, comment: "Index of the element in the list. Starts at 0."
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["index", "menu_category_id"], name: "index_index_menu_category_id", unique: true, where: "(menu_category_id IS NOT NULL)"
    t.index ["index"], name: "index_menu_dishes_in_categories_on_index"
    t.index ["menu_category_id"], name: "index_menu_dishes_in_categories_on_menu_category_id"
    t.index ["menu_dish_id", "menu_category_id"], name: "index_menu_dish_id_menu_category_id", unique: true, where: "(menu_category_id IS NOT NULL)"
    t.index ["menu_dish_id"], name: "index_menu_dishes_in_categories_on_menu_dish_id"
  end

  create_table "menu_ingredients", force: :cascade do |t|
    t.text "status", null: false
    t.jsonb "other", default: {}, null: false
    t.integer "member_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "menu_ingredients_in_dishes", force: :cascade do |t|
    t.bigint "menu_dish_id", null: false
    t.bigint "menu_ingredient_id", null: false
    t.integer "index", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["menu_dish_id", "index"], name: "index_menu_ingredients_in_dishes_on_menu_dish_id_and_index", unique: true
    t.index ["menu_dish_id", "menu_ingredient_id"], name: "index_menu_ingredients_in_dishes_on_dish_and_ingredient", unique: true
    t.index ["menu_dish_id"], name: "index_menu_ingredients_in_dishes_on_menu_dish_id"
    t.index ["menu_ingredient_id"], name: "index_menu_ingredients_in_dishes_on_menu_ingredient_id"
  end

  create_table "menu_tags", force: :cascade do |t|
    t.text "color", null: false
    t.text "status", null: false
    t.jsonb "other", default: {}, null: false
    t.integer "member_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "menu_tags_in_dishes", force: :cascade do |t|
    t.bigint "menu_dish_id", null: false
    t.bigint "menu_tag_id", null: false
    t.integer "index", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["menu_dish_id", "index"], name: "index_menu_tags_in_dishes_on_menu_dish_id_and_index", unique: true
    t.index ["menu_dish_id", "menu_tag_id"], name: "index_menu_tags_in_dishes_on_dish_and_tag", unique: true
    t.index ["menu_dish_id"], name: "index_menu_tags_in_dishes_on_menu_dish_id"
    t.index ["menu_tag_id"], name: "index_menu_tags_in_dishes_on_menu_tag_id"
  end

  create_table "menu_visibilities", force: :cascade do |t|
    t.boolean "public_visible", default: false, null: false
    t.datetime "public_from", precision: nil
    t.datetime "public_to", precision: nil
    t.boolean "private_visible", default: false, null: false
    t.datetime "private_from", precision: nil
    t.datetime "private_to", precision: nil
    t.time "daily_from", comment: "From this time and until daily_to, the category will be visible in the public page.\n        Useful in case you'd want to show \"Lunch\" menu only from 12:00 to 15:00.\n        If daily_to is nil, it will be visible until the end of the day.\n        If daily_from is nil, it will be visible from the beginning of the day."
    t.time "daily_to"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "mobility_string_translations", force: :cascade do |t|
    t.string "locale", null: false
    t.string "key", null: false
    t.string "value"
    t.string "translatable_type"
    t.bigint "translatable_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["translatable_id", "translatable_type", "key"], name: "index_mobility_string_translations_on_translatable_attribute"
    t.index ["translatable_id", "translatable_type", "locale", "key"], name: "index_mobility_string_translations_on_keys", unique: true
    t.index ["translatable_type", "key", "value", "locale"], name: "index_mobility_string_translations_on_query_keys"
  end

  create_table "mobility_text_translations", force: :cascade do |t|
    t.string "locale", null: false
    t.string "key", null: false
    t.text "value"
    t.string "translatable_type"
    t.bigint "translatable_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["translatable_id", "translatable_type", "key"], name: "index_mobility_text_translations_on_translatable_attribute"
    t.index ["translatable_id", "translatable_type", "locale", "key"], name: "index_mobility_text_translations_on_keys", unique: true
  end

  create_table "nexi_http_requests", force: :cascade do |t|
    t.jsonb "request_body", null: false
    t.jsonb "response_body"
    t.text "url", null: false
    t.integer "http_code", null: false
    t.string "http_method", null: false
    t.datetime "started_at", precision: nil, null: false
    t.datetime "ended_at", precision: nil, null: false
    t.string "record_type"
    t.bigint "record_id", comment: "Optionally specify a record this http request belongs to"
    t.text "purpose", comment: "Specify the reason this request was made, optional"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "html_response"
    t.index ["record_type", "record_id"], name: "index_nexi_http_requests_on_record"
  end

  create_table "nexi_order_outcome_requests", force: :cascade do |t|
    t.jsonb "body"
    t.jsonb "headers"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "preferences", force: :cascade do |t|
    t.text "key", null: false
    t.text "value"
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id", "key"], name: "index_preferences_on_user_id_and_key", unique: true
    t.index ["user_id"], name: "index_preferences_on_user_id"
  end

  create_table "preorder_reservation_dates", force: :cascade do |t|
    t.date "date", null: false
    t.bigint "reservation_turn_id", null: false
    t.bigint "group_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["date", "reservation_turn_id"], name: "index_date_reservation_turn_uniqueness", unique: true
    t.index ["group_id"], name: "index_preorder_reservation_dates_on_group_id"
    t.index ["reservation_turn_id"], name: "index_preorder_reservation_dates_on_reservation_turn_id"
  end

  create_table "preorder_reservation_groups", force: :cascade do |t|
    t.text "title", null: false, comment: "Comment for admins that define payment required cases"
    t.text "status", null: false, comment: "Is this case enabled?"
    t.datetime "active_from", comment: "From when this case is enabled. When nil, is enabled from its creation date."
    t.datetime "active_to", comment: "Until when this case is enabled. when nil, is enable forever"
    t.text "preorder_type", null: false, comment: "What should ask the user to do. Will include provider name. May be something like 'paypal_payment', or 'nexi_card_hold'..."
    t.float "payment_value", comment: "How much should people be required to pay if it's a payment. Since may be card hold, this field can be nil."
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "preorder_reservation_groups_to_turns", force: :cascade do |t|
    t.bigint "reservation_turn_id", null: false
    t.bigint "preorder_reservation_group_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["preorder_reservation_group_id"], name: "preorder_reservation_groups_to_turns_group_id"
    t.index ["reservation_turn_id"], name: "preorder_reservation_groups_to_turns_turn_id", unique: true
  end

  create_table "public_messages", force: :cascade do |t|
    t.text "key", null: false, comment: "position id where the message should be shown"
    t.text "status", default: "active", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_public_messages_on_key", unique: true
  end

  create_table "refresh_tokens", force: :cascade do |t|
    t.text "secret", null: false
    t.datetime "expires_at", precision: nil, null: false
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["secret"], name: "index_refresh_tokens_on_secret"
    t.index ["user_id"], name: "index_refresh_tokens_on_user_id"
  end

  create_table "reservation_payments", force: :cascade do |t|
    t.text "hpp_url", null: false, comment: "URL where user can complete the payment. HPP stands for \"Hosted Payment Page\""
    t.float "value", null: false, comment: "EUR user is required to pay."
    t.text "status", null: false, comment: "Will show if payment has been made."
    t.bigint "reservation_id", null: false
    t.text "preorder_type", null: false, comment: "What should ask the user to do. Will include provider name. May be something like 'paypal_payment', or 'nexi_card_hold'..."
    t.jsonb "other", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "html"
    t.text "external_id"
    t.text "success_url"
    t.text "failure_url"
    t.index ["hpp_url"], name: "index_reservation_payments_on_hpp_url", unique: true
    t.index ["reservation_id"], name: "index_reservation_payments_on_reservation_id", unique: true
  end

  create_table "reservation_tags", force: :cascade do |t|
    t.text "title", null: false
    t.text "bg_color", null: false
    t.text "color", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["title"], name: "index_reservation_tags_on_title", unique: true
  end

  create_table "reservation_turn_messages", force: :cascade do |t|
    t.date "from_date", comment: "When user tries to reserve for the associated reservation turn after this date, the message will be shown. If date is nil, the message will be shown for all dates."
    t.date "to_date", comment: "When user tries to reserve for the associated reservation turn before this date, the message will be shown. If date is nil, the message will be shown for all dates. To set a message for exactly one date, set from_date and to_date to the same date."
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "reservation_turn_to_messages", force: :cascade do |t|
    t.bigint "reservation_turn_id", null: false
    t.bigint "reservation_turn_message_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["reservation_turn_id"], name: "turn_id_reservation_turn_to_messages"
    t.index ["reservation_turn_message_id"], name: "message_id_reservation_turn_to_messages"
  end

  create_table "reservation_turns", force: :cascade do |t|
    t.time "starts_at", null: false
    t.time "ends_at", null: false
    t.text "name", null: false
    t.integer "weekday", null: false
    t.integer "step", default: 30, null: false, comment: "minutes between one valid reservation time and the next one. Set to 1 to allow any minute."
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["weekday"], name: "index_reservation_turns_on_weekday"
  end

  create_table "reservations", force: :cascade do |t|
    t.text "fullname", null: false
    t.datetime "datetime", precision: nil, null: false
    t.text "status", null: false
    t.text "secret", null: false
    t.integer "children", default: 0
    t.integer "adults", default: 0
    t.text "table"
    t.text "notes"
    t.text "email"
    t.text "phone"
    t.jsonb "other", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "lang", default: "en", null: false
  end

  create_table "reset_password_secrets", force: :cascade do |t|
    t.text "secret", null: false
    t.bigint "user_id", null: false
    t.datetime "expires_at", precision: nil, default: -> { "(now() + 'PT15M'::interval)" }, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["secret"], name: "index_reset_password_secrets_on_secret", unique: true
    t.index ["user_id"], name: "index_reset_password_secrets_on_user_id"
  end

  create_table "settings", force: :cascade do |t|
    t.text "key", null: false
    t.text "value"
    t.text "parser", comment: "How to parse the value. When nil, do nothing."
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_settings_on_key", unique: true
  end

  create_table "tag_in_reservations", force: :cascade do |t|
    t.bigint "reservation_id", null: false
    t.bigint "reservation_tag_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["reservation_id", "reservation_tag_id"], name: "reservation_id_on_tags", unique: true
    t.index ["reservation_id"], name: "index_tag_in_reservations_on_reservation_id"
    t.index ["reservation_tag_id"], name: "index_tag_in_reservations_on_reservation_tag_id"
  end

  create_table "users", force: :cascade do |t|
    t.text "fullname"
    t.text "username"
    t.text "email", null: false
    t.text "password_digest", null: false
    t.text "status", null: false
    t.datetime "root_at", precision: nil, comment: "Datetime when user became root. Won't ask password for a while."
    t.boolean "can_root", default: false, comment: "Can this user become root?"
    t.integer "failed_attempts", default: 0, null: false
    t.text "enc_otp_key"
    t.datetime "locked_at", precision: nil
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["username"], name: "index_users_on_username", unique: true, where: "(username IS NOT NULL)"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "image_to_records", "images"
  add_foreign_key "images", "images", column: "original_id"
  add_foreign_key "log_image_pixel_events", "log_image_pixels", column: "image_pixel_id"
  add_foreign_key "log_image_pixels", "images"
  add_foreign_key "log_image_pixels", "log_delivered_emails", column: "delivered_email_id"
  add_foreign_key "log_model_changes", "users"
  add_foreign_key "log_reservation_events", "reservations"
  add_foreign_key "menu_allergens_in_dishes", "menu_allergens"
  add_foreign_key "menu_allergens_in_dishes", "menu_dishes"
  add_foreign_key "menu_categories", "menu_categories", column: "root_id"
  add_foreign_key "menu_categories", "menu_visibilities"
  add_foreign_key "menu_dish_suggestions", "menu_dishes", column: "dish_id"
  add_foreign_key "menu_dish_suggestions", "menu_dishes", column: "suggestion_id"
  add_foreign_key "menu_dishes_in_categories", "menu_dishes"
  add_foreign_key "menu_ingredients_in_dishes", "menu_dishes"
  add_foreign_key "menu_ingredients_in_dishes", "menu_ingredients"
  add_foreign_key "menu_tags_in_dishes", "menu_dishes"
  add_foreign_key "menu_tags_in_dishes", "menu_tags"
  add_foreign_key "preferences", "users"
  add_foreign_key "preorder_reservation_dates", "preorder_reservation_groups", column: "group_id"
  add_foreign_key "preorder_reservation_dates", "reservation_turns"
  add_foreign_key "preorder_reservation_groups_to_turns", "preorder_reservation_groups"
  add_foreign_key "preorder_reservation_groups_to_turns", "reservation_turns"
  add_foreign_key "refresh_tokens", "users"
  add_foreign_key "reservation_payments", "reservations"
  add_foreign_key "reservation_turn_to_messages", "reservation_turn_messages"
  add_foreign_key "reservation_turn_to_messages", "reservation_turns"
  add_foreign_key "reset_password_secrets", "users"
  add_foreign_key "tag_in_reservations", "reservation_tags"
  add_foreign_key "tag_in_reservations", "reservations"
end
