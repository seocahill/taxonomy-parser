class DiscoverableTaxonomySet < TaxonomyParser::BaseModel

  attr_reader :id, :name

  attr_accessor :role_types

  def initialize(index, name)
    @id = index + 1
    @name = name
  end
end

class DiscoverableTaxonomySetSerializer < TaxonomyParser::BaseSerializer
  has_many :role_types, include_data: true
  
  attribute :name
end