class Permission < ApplicationRecord
    # Serialize to transform attributes in array
    # Ex: models_create: [:controller1, :controller2, :controller3]
    serialize :models_create, Array 
    serialize :models_read, Array
    serialize :models_update, Array
    serialize :models_destroy, Array
    serialize :models_manage, Array
end
