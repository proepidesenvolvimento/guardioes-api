class Manager < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :database_authenticatable,
         :jwt_authenticatable,
         jwt_revocation_strategy: JWTBlacklist

  belongs_to :app
  belongs_to :permission, dependent: :destroy
end
