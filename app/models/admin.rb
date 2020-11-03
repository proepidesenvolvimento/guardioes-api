class Admin < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :database_authenticatable,
         :jwt_authenticatable,
         jwt_revocation_strategy: JWTBlacklist

  belongs_to :app
  has_one :permission, dependent: :destroy

  validates_presence_of :first_name, :last_name, :email, :app_id
  
  # validates :first_name, 
  #   presence: true,
  #   length: {
  #     minimum: 1,
  #     maximum: 255,
  #     too_short: I18n.translate("admin.validations.first_name.too_short"),
  #     too_long: I18n.translate("admin.validations.first_name.too_long")
  #   }
  # validates :last_name,
  #   presence: true,
  #   length: {
  #     minimum: 1,
  #     too_short: I18n.translate("admin.validations.last_name.too_short"),
  #     maximum: 255,
  #     too_long: I18n.translate("admin.validations.last_name.too_long")
  #   }
  # validates :email, 
  #   presence: true,
  #   format: { with: URI::MailTo::EMAIL_REGEXP, message: I18n.translate("validations.email.message") },
  #   length: {
  #     minimum: 1,
  #     too_short: I18n.translate("admin.validations.email.too_short"),
  #     maximum: 255,
  #     too_long: I18n.translate("admin.validations.email.too_long")
  #   }    
end
