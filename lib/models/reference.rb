class Reference

  attr_reader :id, :element
  attr_accessor :reference_data
  
  def initialize(id, element)
    @id = id
    @element = element
  end
end

class ReferenceSerializer
  include JSONAPI::Serializer

  has_one :element

  attributes :reference_data
end