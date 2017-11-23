class ReferenceSerializer < TaxonomyParser::BaseSerializer
  has_one :element

  attributes :reference_data
end