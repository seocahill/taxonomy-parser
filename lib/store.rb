require 'singleton'

module TaxonomyParser
  class Store
    include Singleton

    attr_reader :dts, :index

    def initialize
      @data = {}
      @index = {}
      @dts = DTSParser.parse
    end

    def get_data
      @data
    end

  end
end