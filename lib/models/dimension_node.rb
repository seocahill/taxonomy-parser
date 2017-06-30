class DimensionNode

  attr_reader :id, :role_type_id, :element, :parent, :order, :arcrole

  def initialize(id, element, parent, order, arcrole)
    @id = id
    @element = element
    @parent = parent
    @order = order
    @arcrole = arcrole
  end

  def name
    self.element.name
  end
end

class DimensionNodeSerializer
  include JSONAPI::Serializer

  has_one :element
  has_one :parent, include_links: false, include_data: true

  attributes :order, :arcrole, :name
end