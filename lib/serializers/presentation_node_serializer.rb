class PresentationNodeSerializer < TaxonomyParser::BaseSerializer
  has_one :role_type
  has_one :element, include_link: false, include_data: true
  has_one :parent, include_data: true

  attributes :order, :name
end