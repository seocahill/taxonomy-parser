class RoleType

  attr_reader :id, :discoverable_taxonomy_set_id, :definition

  def initialize(id, discoverable_taxonomy_set_id, definition)
    @id = id
    @discoverable_taxonomy_set_id = discoverable_taxonomy_set_id
    @definition = definition
  end
end

require 'jsonapi-serializers'

class RoleTypeSerializer
  include JSONAPI::Serializer

  attributes :discoverable_taxonomy_set_id, :definition
end