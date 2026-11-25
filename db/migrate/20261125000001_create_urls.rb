class CreateUrls < ActiveRecord::Migration[8.0]
  def change
    create_table :urls do |t|
      t.string :short_code, null: false
      t.text :long_url, null: false
      t.datetime :expires_at
      t.boolean :is_active, null: false, default: true

      t.timestamps
    end

    add_index :urls, :short_code, unique: true
  end
end
