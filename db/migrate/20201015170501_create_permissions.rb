class CreatePermissions < ActiveRecord::Migration[5.2]
  def change
    create_table :permissions do |t|
      t.text :models_create
      t.text :models_read
      t.text :models_update
      t.text :models_destroy
      t.text :models_manage

      t.timestamps
      #right
    end
  end
end
