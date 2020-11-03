class AddPermissionToManager < ActiveRecord::Migration[5.2]
  def change
    add_reference :managers, :permission, foreign_key: true
    add_reference :admins, :permission, foreign_key: true
    add_reference :group_managers, :permission, foreign_key: true
  end
end
#Permission migration