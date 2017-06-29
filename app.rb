ENV['RACK_ENV'] ||= 'development'

require 'bundler'
Bundler.require :default, ENV['RACK_ENV'].to_sym

require 'json'
require 'set'
require_relative 'lib/application_controller.rb'

module TaxonomyParser
  class Base < Sinatra::Base
    set :server, :puma

    def initialize
      puts "booting app"
      $app = ApplicationController.new
      super
    end

    get '/discoverable_taxonomy_sets' do
      content_type :json
      $app.discoverable_taxonomy_sets
    end

    get '/discoverable_taxonomy_sets/:id' do
      content_type :json
      $app.discoverable_taxonomy_set(params['id'])
    end

    get '/role_types/:id' do
      content_type :json
      $app.role_type(params['id'])
    end

    get '/elements/:id' do
      content_type :json
      $app.element(params['id'])
    end

    get '/presentation_nodes/:id' do
      content_type :json
      $app.presentation_node(params['id'])
    end

    get '/dimension_nodes/:id' do
      content_type :json
      $app.dimension_node(params['id'])
    end

    get '/elements/:id/dimension_nodes' do
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
end