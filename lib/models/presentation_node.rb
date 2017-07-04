class PresentationNode

  attr_reader :id, :role_type_id, :element, :parent, :order

  def initialize(id, role_type_id, element, parent, order)
    @id = id
    @role_type_id = role_type_id
    @element = element
    @parent = parent
    @order = order
  end

  def name 
    element.name
  end
end

class PresentationNodeSerializer
  include JSONAPI::Serializer

  has_one :element, include_link: false, include_data: true
  has_one :parent, include_data: true

  attributes :order, :name

end