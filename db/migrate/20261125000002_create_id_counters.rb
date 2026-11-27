class CreateIdCounters < ActiveRecord::Migration[8.0]
  def change
    create_table :id_counters, id: false do |t|
      t.string :name, null: false, primary_key: true
      t.bigint :value, null: false, default: 0
    end
  end
end
