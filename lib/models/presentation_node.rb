class PresentationNode

  attr_reader :id, :role_type_id, :element_id, :parent, :order
  attr_accessor :element

  def initialize(id, role_type_id, element_id, parent, order)
    @id = id
    @role_type_id = role_type_id
    @element_id = element_id
    @parent = parent
    @order = order
  end
end

require 'jsonapi-serializers'

class PresentationNodeSerializer
  include JSONAPI::Serializer

  has_one :element, include_links: false, include_data: true
  has_one :parent, include_links: false, include_data: true

  has_many :dimension_nodes, include_links: true

  attributes :role_type_id, :element_id, :order
end