require_relative 'parsers/schema'
require_relative 'parsers/presentation'
require_relative 'parsers/label'
require_relative 'parsers/reference'
require_relative 'parsers/dimension'

require_relative 'models/discoverable_taxonomy_set'
require_relative 'models/role_type'
require_relative 'models/presentation_node'
require_relative 'models/element'

require 'SecureRandom'

module TaxonomyParser
  class TaxonomyParser
    include SchemaParser
    include PresentationParser
    include ReferenceParser
    include LabelParser
    include DimensionParser

    attr_accessor :store, :concepts

    def initialize # (lang=en, dts=uk-gaap)
      @current_dts = nil
      @store = {}
      @nodes = {}
      @checksums = {}
      @discoverable_taxonomy_sets = parse_available_dts
      @concepts, @role_types = parse_dts_schemas
      @label_items = parse_label_linkbases
      @reference_items = parse_reference_linkbases
      @presentation_links = parse_presentation_linkbases
      @definitions = parse_definition_linkbases
    end

    def discoverable_taxonomy_sets
      JSONAPI::Serializer.serialize(@discoverable_taxonomy_sets, is_collection: true).to_json
    end

    def discoverable_taxonomy_set(id)
      @current_dts = @discoverable_taxonomy_sets.find { |dts| dts.id == id }
      parse_current_dts
      JSONAPI::Serializer.serialize(@current_dts, include: ['role-types']).to_json
    end

    def role_type(id)
      role_type = @store[:role_types].find { |role_type| role_type.id == id }
      role_type.presentation_nodes = @store[:presentation_nodes].select { |node| node.role_type_id == role_type.id }
      JSONAPI::Serializer.serialize(role_type, include: ['presentation-nodes', 'presentation-nodes.element']).to_json
    end

    private

    def parse_current_dts
      parse_roles
      parse_elements
      parse_presentation_nodes
      # parse_elements
    end

    def hashify_xml(xml)
      xml.each_with_object({}) { |(k,v), hsh| hsh[k] = v }
    end

    def parse_available_dts
      %w[uk-gaap uk-ifrs ie-gaap ie-ifrs].map { |name| DiscoverableTaxonomySet.new(name) }
    end
  end

  $app ||= TaxonomyParser.new
end
