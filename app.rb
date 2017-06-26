require 'sinatra'
require 'nokogiri'
require 'json'
require 'pry'
require 'set'
require './lib/taxonomy_parser'
require 'jsonapi-serializers'

configure { set :server, :puma }

get '/discoverable-taxonomy-sets' do
  content_type :json
  $app.get_available_dts
end

get '/discoverable-taxonomy-sets/:id' do
  content_type :json
  $app.dts(params['id'])
end

get '/graph' do
  content_type :json
  $app.graph
end

get '/menu' do
  content_type :json
  $app.menu.to_json
end

get '/dimensions' do
  content_type :json
  $app.all_dimensions.to_json
end

get '/concepts/:id' do
  content_type :json
  $app.find_concept(params['id'])
end

