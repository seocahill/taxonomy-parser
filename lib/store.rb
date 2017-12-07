require 'singleton'

module TaxonomyParser
  class Store
    include Singleton

    attr_reader :dts, :index, :data

    def initialize
      @data = {}
      @index = {}
      @dts = DTSParser.parse
    end

  end
end