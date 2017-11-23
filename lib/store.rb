require 'singleton'

module TaxonomyParser
  class Store
    include Singleton

    attr_reader :dts

    def initialize
      @data = {}
      @dts = DTSParser.parse
    end

    def get_data
      @data
    end

  end
end