ENV['RACK_ENV'] = 'test'
require 'minitest/autorun'
# require 'pry-rescue/minitest'
require 'rack/test'
require_relative '../app'

class APITest < MiniTest::Test
  include Rack::Test::Methods

  def app
    TaxonomyParser::Base
  end

  def test_hello_world
    get '/discoverable_taxonomy_sets'
    assert last_response.ok?, "should be ok"
    assert_equal 2, JSON.parse(last_response.body)["data"].length, "should return 2 DTS"
  end
end