class CreatePhoneNumbers < ActiveRecord::Migration[7.0]
  def change
    create_table :phone_numbers, id: :uuid do |t|
      t.string :value, null: false
      t.boolean :can_receive_messages, null: false, default: true
      t.timestamps

      t.index :value, name: :value_uniqueness, unique: true
    end
  end
end
