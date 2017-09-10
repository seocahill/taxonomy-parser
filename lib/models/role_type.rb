class RoleType < TaxonomyParser::BaseModel

  attr_reader :id, :discoverable_taxonomy_set_id, :definition, :role_uri, :order, :network
  attr_accessor :presentation_nodes

  def initialize(id, discoverable_taxonomy_set_id, definition, role_uri, network)
    @id = id
    @discoverable_taxonomy_set_id = discoverable_taxonomy_set_id
    @definition = definition
    @role_uri = role_uri
    @network = network
    @presentation_nodes = []
  end

  def order
    self.definition.split().first.to_i
  end
end

class RoleTypeSerializer < TaxonomyParser::BaseSerializer
  include JSONAPI::Serializer

  has_many :presentation_nodes

  attributes :definition, :order
end