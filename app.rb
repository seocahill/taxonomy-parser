require 'sinatra'
require 'nokogiri'
require 'json'
require 'pry'
require 'set'
require './lib/taxonomy_parser'

configure { set :server, :puma }

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
