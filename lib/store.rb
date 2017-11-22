require 'singleton'

module TaxonomyParser
  class Store
    include Singleton

    def initialize
      @data = {}
    end

    def get_data
      @data
    end
  end
end