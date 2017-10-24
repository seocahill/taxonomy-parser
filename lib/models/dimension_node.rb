class DimensionNode < TaxonomyParser::BaseModel

  attr_reader :element, :order, :arcrole
  attr_accessor :id, :default, :has_defaults, :parent

  def initialize(id:, element:, parent: nil, order: "0", arcrole: nil)
    @id = id
    @element = element
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
    self.element.id
  end

  def default_dimension
    self.default
  end
end

class DimensionNodeSerializer < TaxonomyParser::BaseSerializer
  has_one :element, include_links: false, include_data: true
  has_one :parent, include_links: false, include_data: true
  has_one :default_dimension, include_links: false, include_data: true

  attributes :order, :name, :tag, :has_defaults, :arcrole
end