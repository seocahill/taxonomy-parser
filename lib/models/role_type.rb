class RoleType

  attr_reader :id, :discoverable_taxonomy_set_id, :definition, :role_uri, :order, :network
  attr_accessor :presentation_nodes

  def initialize(id, discoverable_taxonomy_set_id, definition, role_uri, network)
    @id = id
    @discoverable_taxonomy_set_id = discoverable_taxonomy_set_id
    @definition = definition
    @role_uri = role_uri
    @network = network
  end

  def order
    self.definition.split().first.to_i
  end
end

class RoleTypeSerializer
  include JSONAPI::Serializer

  has_many :presentation_nodes, include_links: false

  attributes :definition, :order
end