class AddGoDataUserId < ActiveRecord::Migration[5.2]
  def change
    add_column :group_managers, :userid_godata, :text
  end
end
