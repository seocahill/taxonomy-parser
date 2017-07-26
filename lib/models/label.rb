class Label

  attr_reader :id, :element
  attr_accessor :label, :documentation, :period_start_label, :period_end_label, :verbose_label
  
  def initialize(id, element)
    @id = id
    @element = element
  end
end

class LabelSerializer
  include JSONAPI::Serializer

  has_one :element

  attributes :label, :documentation, :period_start_label, :period_end_label, :verbose_label
end