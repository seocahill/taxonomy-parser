require 'sinatra'
require 'nokogiri'
require 'json'
require 'pry'
require 'set'
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
  network = params['network']
  content_type :json
  $app.menu(network)
end

get '/links' do
  content_type :json
  $app.links
end

get '/role-types/:role' do
  role = params['role']
  content_type :json
  $app.role_types(role)
end

get '/checksums' do
  content_type :json
  $app.checksums
end

get '/concepts/:id' do
  content_type :json
  $app.find_concept(params['id'])
end
