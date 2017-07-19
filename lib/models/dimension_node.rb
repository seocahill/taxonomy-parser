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
    self.element.labels.first.label
  end
end

class DimensionNodeSerializer
  include JSONAPI::Serializer

  has_one :element
  has_one :parent, include_links: false, include_data: true

  attributes :order, :arcrole, :name

  def base_url
    "/api/v1"
  end

  def self_link
    "#{base_url}/dimension_nodes/#{id}"
  end
end