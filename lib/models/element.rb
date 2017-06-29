class Element

  attr_reader :id, :discoverable_taxonomy_set_id, :name, :item_type, :substitution_group, :period_type, :abstract, :nillable
  attr_accessor :dimension_nodes
  
  def initialize(id, discoverable_taxonomy_set_id, name, item_type, substitution_group, period_type, abstract, nillable)
    @id = id
    @discoverable_taxonomy_set_id = discoverable_taxonomy_set_id
    @name = name
    @item_type = item_type
    @substitution_group = substitution_group
    @period_type = period_type
    @abstract = abstract
    @nillable = nillable
  end
end

class ElementSerializer
  include JSONAPI::Serializer

  has_many :presentation_nodes 
  has_many :dimension_nodes

  attributes :name, :item_type, :substitution_group, :period_type, :abstract, :nillable
end