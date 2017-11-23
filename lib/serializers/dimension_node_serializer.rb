class DimensionNodeSerializer < TaxonomyParser::BaseSerializer
  has_one :element, include_links: false, include_data: true
  has_one :parent, include_links: false, include_data: true
  has_one :default_dimension, include_links: false, include_data: true

  attributes :order, :name, :tag, :has_defaults, :arcrole
end