class UserSerializer < ActiveModel::Serializer
  attributes :id, :user_name, :email, :birthdate, :country, :gender, :race, :is_professional, :city, :state, :identification_code, :group_id, :risk_group, :group, :streak, :policy_version, :created_at, :is_vigilance, :phone

  belongs_to :app do
    link(:app) {app_url(object.app.id)}
  end

  has_many :households 
  # has_many :surveys

  def group
    if object.group.nil?
      return nil
    end
    object.group.get_path(string_only=true,labled=false).join('/')
  end

  def attributes(*args)
    h = super(*args)
    h[:birthdate] = object.birthdate.to_time.iso8601 unless object.birthdate.blank?
    h
  end

end