class PresentationNode

  attr_reader :id, :role_type_id, :role_type, :element, :parent_id, :order
  attr_accessor :parent

  def initialize(id, role_type, element, parent_id, order)
    @id = id
    @role_type = role_type
    @element = element
    @parent_id = parent_id
    @order = order
  end

  def role_type_id
    self.role_type.id
  end

  def name 
    element.labels.first.label
  end
end

class PresentationNodeSerializer
  include JSONAPI::Serializer

  has_one :role_type
  has_one :element, include_link: false, include_data: true
  has_one :parent, include_data: true do
    $app.store[:presentation_nodes][object.parent_id]
  end

  attributes :order, :name
end