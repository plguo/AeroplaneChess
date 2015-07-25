class CreateGames < ActiveRecord::Migration
  def change
    create_table :games do |t|
      t.integer :state, default: 0, null: false
      t.integer :turn, default: 0
      t.integer :steps, default: 0, null: false
      t.integer :stage, default: 0, null: false

      t.timestamps null: false
    end
  end
end
