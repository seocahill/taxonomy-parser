class DiscoverableTaxonomySet

  attr_reader :id, :name

  def initialize(name)
    @name = name
    @id = SecureRandom.uuid
  end
end