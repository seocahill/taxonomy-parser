class Reference < TaxonomyParser::BaseModel

  attr_reader :id, :element
  attr_accessor :reference_data
  
  def initialize(id, element)
    @id = id
    @element = element
  end
end

class ReferenceSerializer < TaxonomyParser::BaseSerializer
  include JSONAPI::Serializer

  has_one :element

  attributes :reference_data
end