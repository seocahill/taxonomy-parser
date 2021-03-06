class Element < TaxonomyParser::BaseModel

  attr_reader :id, :discoverable_taxonomy_set_id, :name, :item_type, :substitution_group, 
    :period_type, :abstract, :nillable
    
  attr_accessor :dimension_nodes, :labels, :max_occurs, :min_occurs, :tuple_id, 
    :presentation_nodes, :invertible, :reference, :default_dimensions, :must_choose_dimension
  
  def initialize(id, discoverable_taxonomy_set_id, name, item_type, substitution_group, period_type, abstract, nillable)
    @id = id
    @discoverable_taxonomy_set_id = discoverable_taxonomy_set_id
    @name = name
    @item_type = item_type
    @substitution_group = substitution_group
    @period_type = period_type
    @abstract = abstract
    @nillable = nillable
    @labels = []
    @presentation_nodes = []
    @invertible = false
    @default_dimensions = true
    @must_choose_dimension = false
  end
end