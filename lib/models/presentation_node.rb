class PresentationNode < TaxonomyParser::BaseModel

  attr_reader :role_type, :element, :href
  attr_accessor :id, :parent, :order, :aliases

  def initialize(id, role_type, element, href)
    @id = id
    @role_type = role_type
    @element = element
    @href = href
    @aliases = []
  end

  def name 
    element.labels.first.label
  end
end