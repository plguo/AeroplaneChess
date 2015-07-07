class CreatePlayers < ActiveRecord::Migration
  def change
    create_table :players do |t|
      t.string :name
      t.integer :color, null: false
      t.integer :state, default: 0, null: false
      t.string :raw_chesses

      t.boolean :robot, default: false, null: false

      t.belongs_to :game, index: true

      t.timestamps null: false
    end
  end
end
