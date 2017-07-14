require_relative 'parsers/schema'
require_relative 'parsers/presentation'
require_relative 'parsers/label'
require_relative 'parsers/reference'
require_relative 'parsers/dimension'

require_relative 'models/discoverable_taxonomy_set'
require_relative 'models/role_type'
require_relative 'models/presentation_node'
require_relative 'models/element'
require_relative 'models/dimension_node'

require 'securerandom'

module TaxonomyParser
  class ApplicationController 
    include SchemaParser
    include PresentationParser
    include ReferenceParser
    include LabelParser
    include DimensionParser

    def initialize
      puts "initialized"
      @current_dts = nil
      @store = {}
      @nodes = {}
      @checksums = {}
      parse_available_dts
    end

    def discoverable_taxonomy_sets
      JSONAPI::Serializer.serialize(@store[:discoverable_taxonomy_sets].values, is_collection: true).to_json
    end

    def discoverable_taxonomy_set(id)
      @current_dts = @store[:discoverable_taxonomy_sets][id.to_i]
      parse_current_dts if @current_dts.role_types.nil?
      JSONAPI::Serializer.serialize(@current_dts, include: ['role-types']).to_json
    end

    def role_types(params)
      role_types = @store[:role_types].values
      JSONAPI::Serializer.serialize(role_types, is_collection: true).to_json
    end

    def role_type(id)
      role_type = @store[:role_types][id.to_i]
      JSONAPI::Serializer.serialize(role_type, include: ['presentation-nodes', 'presentation-nodes.element']).to_json
    end

    def element(id)
      element = @store[:elements][id]
      element.dimension_nodes = dimension_node_tree(id)
      JSONAPI::Serializer.serialize(element, include: ['dimension-nodes']).to_json
    end

    def element_dimension_nodes(id)
      dimension_nodes = dimension_node_tree(id)
      JSONAPI::Serializer.serialize(dimension_nodes, is_collection: true).to_json
    end

    def presentation_node(id)
      presentation_node = @store[:presentation_nodes][id]
      element = presentation_node.element
      element.dimension_nodes = dimension_node_tree(element.id)
      JSONAPI::Serializer.serialize(presentation_node, include: ['element.dimension-nodes']).to_json
    end

    def dimension_node(id)
      dimension_node = @store[:dimension_nodes][id]
      JSONAPI::Serializer.serialize(dimension_node, include: ['element']).to_json
    end

    def dimension_node_element(id)
      dimension_node = @store[:dimension_nodes][id]
      JSONAPI::Serializer.serialize(dimension_node.element).to_json
    end

    private

    def parse_current_dts
      @concepts, @role_types = parse_dts_schemas
      @label_items = parse_label_linkbases
      @reference_items = parse_reference_linkbases
      @presentation_links = parse_presentation_linkbases
      @definitions = parse_definition_linkbases
      parse_roles
      parse_elements
      parse_presentation_nodes
    end

    def hashify_xml(xml)
      xml.each_with_object({}) { |(k,v), hsh| hsh[k] = v }
    end

    def parse_available_dts
      @store[:discoverable_taxonomy_sets] = {}
      dts_path = File.join(__dir__, "/../dts_assets")
      # exclude . .. .DS_Store etc
      dts_folders = Dir.entries(dts_path).reject { |file| file[0] == '.' }
      dts_folders.each_with_index do |name, index| 
        model = DiscoverableTaxonomySet.new(index, name)
        @store[:discoverable_taxonomy_sets][model.id] = model
      end
    end
  end
end
