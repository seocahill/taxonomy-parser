ENV['RACK_ENV'] ||= 'development'

require 'bundler'
Bundler.require :default, ENV['RACK_ENV'].to_sym

require 'json'
require 'set'
require './lib/application_controller.rb'

class TaxonomyParser < Sinatra::Base
  set :server, :puma

  def initialize
    puts "booting app"
    $app = ApplicationController.new
    super
  end

  get '/discoverable-taxonomy-sets' do
    content_type :json
    $app.discoverable_taxonomy_sets
  end

  get '/discoverable-taxonomy-sets/:id' do
    content_type :json
    $app.discoverable_taxonomy_set(params['id'])
  end

  get '/role-types/:id' do
    content_type :json
    $app.role_type(params['id'])
  end

  get '/elements/:id' do
    content_type :json
    $app.element(params['id'])
  end

  get '/presentation-nodes/:id' do
    content_type :json
    $app.presentation_node(params['id'])
  end

  get '/dimension-nodes/:id' do
    content_type :json
    $app.dimension_node(params['id'])
  end

  get '/elements/:id/dimension-nodes' do
    content_type :json
    $app.element_dimension_nodes(params['id'])
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
end