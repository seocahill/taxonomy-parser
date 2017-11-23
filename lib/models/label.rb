class Label < TaxonomyParser::BaseModel

  attr_reader :id, :element
  attr_accessor :label, :documentation, :period_start_label, :period_end_label, :verbose_label
  
  def initialize(id, element)
    @id = id
    @element = element
  end
end