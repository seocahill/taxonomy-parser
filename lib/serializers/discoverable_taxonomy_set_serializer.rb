class DiscoverableTaxonomySetSerializer < TaxonomyParser::BaseSerializer
  has_many :role_types, include_data: true
  
  attribute :name
end