class DimensionNode

  attr_reader :id, :element_id, :order, :arcrole
  attr_accessor :default, :has_defaults, :parent

  def initialize(id:, element_id:, parent: nil, order: "0", arcrole: nil)
    @id = id
    @element_id = element_id
    @parent = parent
    @order = order
    @arcrole = arcrole
    @default = nil
    @has_defaults = true
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

  def default_dimension
    self.default
  end
end

class DimensionNodeSerializer
  include JSONAPI::Serializer

  has_one :element, include_links: false, include_data: true
  has_one :parent, include_links: false, include_data: true

  attributes :order, :name, :tag, :has_defaults, :arcrole, :default_dimension

  def base_url
    "/api/v1"
  end

  def self_link
    "#{base_url}/dimension_nodes/#{id}"
  end
end