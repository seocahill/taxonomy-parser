ENV['RACK_ENV'] = 'test'
require 'minitest/autorun'
require_relative './test_helper'
# require 'pry-rescue/minitest'
require 'rack/test'
require_relative '../app'

class APITest < MiniTest::Test
  include Rack::Test::Methods
  include TaxonomyParser::TestHelper

  def app
    TaxonomyParser::Base
  end

  def test_discoverable_taxonomy_sets
    get '/discoverable_taxonomy_sets'
    assert last_response.ok?, "should be ok"
    assert_equal 2, jsonapi_data.length, "should return 2 DTS"
    assert jsonapi_data_includes("name", ["ie-gaap", "uk-gaap"]), "should return correctd DTS data"
  end
end