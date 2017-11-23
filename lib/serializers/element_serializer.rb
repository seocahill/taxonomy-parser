class ElementSerializer < TaxonomyParser::BaseSerializer
  has_many :presentation_nodes, include_links: false, include_data: true
  has_many :labels, include_links: false, include_data: true
  has_many :dimension_nodes, include_links: false, include_data: true
  has_one :reference

  attributes :name, :item_type, :substitution_group, :period_type, :must_choose_dimension,
    :abstract, :nillable, :max_occurs, :min_occurs, :tuple_id, :invertible, :default_dimensions
end