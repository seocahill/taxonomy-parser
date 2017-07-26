class PresentationNode

  attr_reader :role_type, :element, :href
  attr_accessor :id, :parent, :order

  def initialize(id, role_type, element, href)
    @id = id
    @role_type = role_type
    @element = element
    @href = href
  end

  def name 
    element.labels.first.label
  end
end

class PresentationNodeSerializer
  include JSONAPI::Serializer

  has_one :role_type
  has_one :element, include_link: false, include_data: true
  has_one :parent, include_data: true

  attributes :order, :name
end