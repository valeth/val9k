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

ActiveRecord::Schema.define(version: 20180218120836) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "discord_channels", force: :cascade do |t|
    t.bigint "cid", null: false
    t.bigint "sid", null: false
  end

  create_table "quotes", force: :cascade do |t|
    t.bigint "sid", null: false
    t.text "name", null: false
    t.text "content", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "created_by", null: false
  end

  create_table "server_messages", force: :cascade do |t|
    t.bigint "sid", null: false
    t.text "msg_type", null: false
    t.text "content", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "server_settings", force: :cascade do |t|
    t.bigint "sid", null: false
    t.text "key", null: false
    t.json "value", null: false
  end

  create_table "youtube_channels", force: :cascade do |t|
    t.text "channel_id", null: false
    t.text "name"
    t.datetime "next_update"
    t.datetime "created_at", default: "2018-02-13 16:43:16", null: false
    t.datetime "updated_at", default: "2018-02-13 16:43:16", null: false
  end

  create_table "youtube_notification_subscriptions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "youtube_channel_id", null: false
    t.bigint "discord_channel_id", null: false
    t.index ["discord_channel_id"], name: "index_youtube_notification_subscriptions_on_discord_channel_id"
    t.index ["youtube_channel_id"], name: "index_youtube_notification_subscriptions_on_youtube_channel_id"
  end

  create_table "youtube_notification_subscriptions_notifications", id: false, force: :cascade do |t|
    t.bigint "youtube_notification_id"
    t.bigint "youtube_notification_subscription_id"
  end

  create_table "youtube_notifications", force: :cascade do |t|
    t.text "video_id", null: false
    t.text "title", null: false
    t.datetime "published_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "youtube_channel_id", null: false
    t.text "thumbnail_url"
    t.text "description"
    t.index ["youtube_channel_id"], name: "index_youtube_notifications_on_youtube_channel_id"
  end

end
