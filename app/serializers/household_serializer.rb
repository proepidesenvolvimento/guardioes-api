class HouseholdSerializer < ActiveModel::Serializer
  attributes :id, :description, :birthdate, :country, :gender, :race, :kinship,
             :identification_code, :group, :group_id,
             :risk_group, :created_at, :streak
  has_one :user

  def group
    return nil if object.group.nil?
    object.group.get_path(string_only=true,labled=false).join('/')
  end
end
