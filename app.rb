ENV['RACK_ENV'] ||= 'development'

require 'bundler'
Bundler.require :default, ENV['RACK_ENV'].to_sym

require 'json'
require 'set'
require_relative 'lib/application_controller.rb'

module TaxonomyParser
  class Base < Sinatra::Base
    set :server, :puma
    mime_type :api_json, 'application/vnd.api+json'

    def initialize
      puts "booting app...."
      super()
      $app = ApplicationController.new
    end

    get '/discoverable_taxonomy_sets' do
      content_type :api_json
      $app.discoverable_taxonomy_sets
    end

    get '/discoverable_taxonomy_sets/:id' do
      content_type :api_json
      $app.discoverable_taxonomy_set(params['id'])
    end

    get '/role_types' do
      content_type :api_json
      $app.role_types(params)
    end

    get '/role_types/:id' do
      content_type :api_json
      $app.role_type(params['id'])
    end

    get '/role_types/:id/presentation-nodes' do
      content_type :api_json
      $app.role_type_presentation_nodes(params['id'])
    end

    get '/elements/:id' do
      content_type :api_json
      $app.element(params['id'])
    end

    get '/elements/:id/dimension-nodes' do
      content_type :api_json
      $app.element_dimension_nodes(params['id'])
    end

    get '/presentation_nodes' do
      content_type :api_json
      $app.presentation_nodes(params)
    end

    get '/presentation_nodes/:id' do
      content_type :api_json
      $app.presentation_node(params['id'])
    end

    get '/presentation_nodes/:id/role-type' do
      content_type :api_json
      $app.presentation_node_role_type(params['id'])
    end

    get '/dimension_nodes/:id' do
      content_type :api_json
      $app.dimension_node(params['id'])
    end

    get '/dimension_nodes' do
      content_type :api_json
      $app.dimension_nodes(params)
    end

    get '/dimension_nodes/:id/element' do
      content_type :api_json
      $app.dimension_node_element(params['id'])
    end
    
    get '/labels/:id' do
      content_type :api_json
      $app.label(params['id'])
    end

    get '/references/:id' do
      content_type :api_json
      $app.reference(params['id'])
    end
  end
end