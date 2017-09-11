require_relative 'parsers/schema'
require_relative 'parsers/presentation'
require_relative 'parsers/label'
require_relative 'parsers/reference'
require_relative 'parsers/dimension'
require_relative 'parsers/reference'

require_relative 'models/base_model'
require_relative 'models/discoverable_taxonomy_set'
require_relative 'models/role_type'
require_relative 'models/presentation_node'
require_relative 'models/element'
require_relative 'models/dimension_node'
require_relative 'models/label'
require_relative 'models/reference'
require 'logger'

module TaxonomyParser
  class ApplicationController 
    include SchemaParser
    include PresentationParser
    include ReferenceParser
    include LabelParser
    include DimensionParser

    attr_reader :store

    def initialize
      parse_available_dts
      puts "ready!"
    end

    def discoverable_taxonomy_sets
      JSONAPI::Serializer.serialize(@all_dts.values, is_collection: true).to_json
    end

    def discoverable_taxonomy_set(id)
      @current_dts = @all_dts[id.to_i]
      parse_current_dts if @current_dts.role_types.nil?
      JSONAPI::Serializer.serialize(@current_dts, include: ['role-types']).to_json
    end

    def role_types(params)
      role_types = @store[:role_types].values_at(*params["filter"]["id"].split(',').map(&:to_i))
      JSONAPI::Serializer.serialize(role_types, is_collection: true).to_json
    end

    def role_type(id)
      role_type = @store[:role_types][id.to_i]
      JSONAPI::Serializer.serialize(role_type).to_json
    end

    def role_type_presentation_nodes(id)
      role_type = @store[:role_types][id.to_i]
      JSONAPI::Serializer.serialize(role_type.presentation_nodes, is_collection: true).to_json
    end

    def element(id)
      element = @store[:elements][id]
      JSONAPI::Serializer.serialize(element, include: ['presentation-nodes', 'dimension-nodes', 'labels']).to_json
    end

    def element_dimension_nodes(id)
       element = @store[:elements][id]
      JSONAPI::Serializer.serialize(element.dimension_nodes, is_collection: true).to_json
    end

    def presentation_nodes(params)
      presentation_nodes = @store[:presentation_nodes].values_at(*params["filter"]["id"].split(',').map(&:to_i))
      presentation_nodes.each do |node|
        element = node.element
      end
      JSONAPI::Serializer.serialize(presentation_nodes, include: ['element.dimension-nodes', 'element.labels'], is_collection: true).to_json
    end

    def presentation_node(id)
      presentation_node = @store[:presentation_nodes][id.to_i]
      element = presentation_node.element
      JSONAPI::Serializer.serialize(presentation_node, include: ['element.dimension-nodes', 'element.labels']).to_json
    end

    def presentation_node_role_type(id)
      presentation_node = @store[:presentation_nodes][id.to_i]
      role_type = presentation_node.role_type
      JSONAPI::Serializer.serialize(role_type).to_json
    end

    def dimension_node(id)
      dimension_node = @store[:dimension_nodes][id.to_i]
      JSONAPI::Serializer.serialize(dimension_node, include: ['element']).to_json
    end

    def dimension_nodes(params)
      dimension_nodes = @store[:dimension_nodes].values_at(*params["filter"]["id"].split(',').map(&:to_i))
      JSONAPI::Serializer.serialize(dimension_nodes, is_collection: true).to_json
    end

    def dimension_node_element(id)
      dimension_node = @store[:dimension_nodes][id.to_i]
      JSONAPI::Serializer.serialize(dimension_node.element).to_json
    end

    def label(id)
      label = @store[:labels][id.to_i]
      JSONAPI::Serializer.serialize(label).to_json
    end

    def reference(id)
      reference = @store[:references][id.to_i]
      JSONAPI::Serializer.serialize(reference).to_json
    end

    private

    def parse_current_dts
      puts "parsing #{@current_dts.name} DTS"
      @store = {}
      parse_dts
      parse_presentation_linkbases
      parse_definition_linkbases
      parse_label_linkbases
      parse_reference_linkbases
    end

    def parse_available_dts
      @all_dts = {}
      default_dts = ENV.fetch("DTS", "ie-gaap")
      dts_path = File.join(__dir__, "/../dts_assets")

      # exclude . .. .DS_Store etc
      Dir.entries(dts_path).reject do |file| 
        file[0] == '.' 
      end.each_with_index do |name, index| 
        model = DiscoverableTaxonomySet.new(index, name)
        @all_dts[model.id] = model
        discoverable_taxonomy_set(model.id) if name == default_dts
      end
    end
  end
end
