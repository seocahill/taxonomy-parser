class Label

  attr_reader :id, :element
  attr_accessor :label, :documentation, :periodStartLabel, :periodEndLabel, :verboseLabel
  
  def initialize(id, element)
    @id = id
    @element = element
  end
end

class LabelSerializer
  include JSONAPI::Serializer

  has_one :element

  attributes :label, :documentation, :periodStartLabel, :periodEndLabel, :verboseLabel
end