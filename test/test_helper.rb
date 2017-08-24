ENV['RACK_ENV'] = 'test'
require 'simplecov'
SimpleCov.start do 
  add_filter "/test/"
end
require 'minitest/autorun'
require 'rack/test'
require_relative '../app'
# require 'pry-rescue/minitest'

module TaxonomyParser
  module TestHelper

    def json_data(type="data")
      JSON.parse(last_response.body)[type]
    end

    def json_includes(type="data", attr, required)
      actual = json_data(type).map { |model| model["attributes"][attr] }
      (required - actual).empty?
    end
  end
end