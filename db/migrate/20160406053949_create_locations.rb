class CreateLocations < ActiveRecord::Migration
  def change
    create_table :locations do |t|
      t.float :latitude
      t.float :longitude
      t.string :address
      t.integer :category
      t.integer :user_id

      t.timestamps null: false
    end
  end
end
