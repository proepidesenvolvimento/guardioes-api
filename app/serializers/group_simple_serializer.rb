class GroupSimpleSerializer < ActiveModel::Serializer
    attributes :id, :description, :label, :children_label, :location_id_godata, :location_name_godata
end
  