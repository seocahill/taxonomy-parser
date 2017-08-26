class DimensionNode

  attr_reader :id, :element_id, :parent, :order
  attr_accessor :default_id, :has_defaults, :children

  def initialize(id, element_id, parent = nil, order = "0")
    @id = id
    @element_id = element_id
    @parent = parent
    @order = order
    @default_id = nil
    @has_defaults = true
    @children = []
  end

  def element
    $app.store[:elements][self.element_id]
  end

  def name
    self.element.labels.first.label
  end

  def tag
    self.element_id
  end
end

class DimensionNodeSerializer
  include JSONAPI::Serializer

  has_one :element, include_links: false, include_data: true
  has_one :parent, include_links: false, include_data: true

  attributes :order, :name, :tag, :default_id, :has_defaults

  def base_url
    "/api/v1"
  end

  def self_link
    "#{base_url}/dimension_nodes/#{id}"
  end
end