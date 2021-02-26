class AddGoDataLocationInfos < ActiveRecord::Migration[5.2]
  def change
    add_column :groups, :location_name_godata, :text
    add_column :groups, :location_id_godata, :text
  end
end
