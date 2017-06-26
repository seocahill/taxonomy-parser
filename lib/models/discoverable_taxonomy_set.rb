class DiscoverableTaxonomySet

  attr_reader :id, :name

  attr_accessor :role_types

  def initialize(name)
    @name = name
    @id = SecureRandom.uuid
  end
end

require 'jsonapi-serializers'

class DiscoverableTaxonomySetSerializer
  include JSONAPI::Serializer

  has_many :role_types
  
  attribute :name
end