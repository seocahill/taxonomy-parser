class DiscoverableTaxonomySet < TaxonomyParser::BaseModel

  attr_reader :id, :name

  attr_accessor :role_types

  def initialize(index, name)
    @id = index + 1
    @name = name
  end
end