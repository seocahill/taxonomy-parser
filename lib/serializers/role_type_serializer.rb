class RoleTypeSerializer < TaxonomyParser::BaseSerializer
  has_many :presentation_nodes

  attributes :definition, :order
end