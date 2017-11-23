class DimensionNode < TaxonomyParser::BaseModel

  attr_reader :element_id, :order, :arcrole
  attr_accessor :id, :default, :has_defaults, :parent, :element

  def initialize(id:, element_id:, parent: nil, order: "0", arcrole: nil)
    @id = id
    @element_id = element_id
    @parent = parent
    @order = order
    @arcrole = arcrole
    @default = nil
    @has_defaults = true
  end

  def name
    self.element.labels.first.label
  end

  def tag
    self.element_id
  end

  def default_dimension
    self.default
  end
end