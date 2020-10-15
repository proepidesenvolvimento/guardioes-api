class Permission < ApplicationRecord
    serialize :models_create, Array
    serialize :models_read, Array
    serialize :models_update, Array
    serialize :models_destroy, Array
    serialize :models_manage, Array

    belongs_to :manager
end
