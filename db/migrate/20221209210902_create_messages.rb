class CreateMessages < ActiveRecord::Migration[7.0]
  def up
    create_enum :message_status, %w{
      initiated
      delivered
      failed
      undeliverable
      external_request_failed
    }

    create_table :messages, id: :uuid, force: :cascade do |t|
      t.string :external_id
      t.enum "current_status", default: "initiated", null: false, enum_type: "message_status"
      t.references :phone_number, type: :uuid, index: true, null: false, foreign_key: true
      t.string :body, null: false

      t.timestamps
    end
  end

  def down
    drop_table :messages, force: :cascade

    execute <<-SQL
      DROP TYPE message_status;
    SQL
  end
end
