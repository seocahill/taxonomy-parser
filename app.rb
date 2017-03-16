require 'sinatra'
require 'nokogiri'
require 'json'
require 'pry'
require 'set'
require 'jsonapi/renderer'
require './lib/taxonomy_parser'

configure { set :server, :puma }

#  Explore
# 1 - render the presentation graph
# node id parent_id label element_id
#
# 2 - render the primary items
#
#  Tag
# 1 - render role menu
# 2 - render presentation graph for that role
# 3 - render dimension graph for selected concept if dimensional
# 4 - render tuple members for selected concept if tuple
#

get '/graph' do
  content_type :json
  $app.graph
end

get '/menu' do
  content_type :json
  $app.menu.to_json
  # roles = $app.menu.map {|item| RoleResource.new(item)}
  # JSONAPI.render(data: roles).to_json
end

get '/dimensions' do
  content_type :json
  $app.all_dimensions.to_json
end

get '/concepts/:id' do
  content_type :json
  $app.find_concept(params['id'])
end

class RoleResource
  attr_accessor :id, :label

  def initialize(role)
    @id = role[:id]
    @label = role[:label]
  end

  def jsonapi_type
    'roles'
  end

  def jsonapi_id
    @id.to_s
  end

  def jsonapi_related(included)
    {}
  end

  def as_jsonapi(options = {})
    fields = options[:fields] || [:label]
    included = options[:include] || []
    hash = { id: jsonapi_id, type: jsonapi_type }
    hash[:attributes] = { label: @label }.select { |k, _| fields.include?(k) }
    hash
  end
end

