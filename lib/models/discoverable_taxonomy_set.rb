class DiscoverableTaxonomySet

  attr_reader :id, :name

  attr_accessor :role_types

  def initialize(name)
    @id = SecureRandom.uuid
    @name = name
  end
end

class DiscoverableTaxonomySetSerializer
  include JSONAPI::Serializer

  has_many :role_types, include_links: false, include_data: true
  
  attribute :name
end