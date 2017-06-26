require_relative 'parsers/schema'
require_relative 'parsers/presentation'
require_relative 'parsers/label'
require_relative 'parsers/reference'
require_relative 'parsers/dimension'

require_relative 'models/discoverable-taxonomy-set'

require 'SecureRandom'

module TaxonomyParser
  class TaxonomyParser
    include SchemaParser
    include PresentationParser
    include ReferenceParser
    include LabelParser
    include DimensionParser

    def initialize # (lang=en, dts=uk-gaap)
      @nodes = {}
      @checksums = {}
      @concepts, @role_types = parse_dts_schemas
      @label_items = parse_label_linkbases
      @reference_items = parse_reference_linkbases
      @presentation_links = parse_presentation_linkbases
      @definitions = parse_definition_linkbases
    end

    def graph
      populate_links
      {
        nodes: @nodes.values,
        concepts: @concepts.map { |k,v| v.merge(id: k) },
        labels: @label_items,
        references: @reference_items
      }.to_json
    end

    def menu
      @role_types.select { |k,v|
        v["usedOn"] == "link:presentationLink"
      }.map { |k,v|
        { id: k, label: v["definition"] }
      }.sort_by { |node|
        node[:label].split().first.to_i
      } #.to_json
    end

    def all_dimensions
      dimension_nodes = []
      @concepts.keys.each do |concept_id|
        dimension_nodes << dimension_node_tree(concept_id)
      end
      dimension_nodes
    end

    def role_types(role)
      roleURI = "http://www.xbrl.org/uk/role/" + role
      nodes_for_role(@links[roleURI]).to_json
    end

    def find_concept(id)
      dimension_node_tree(id).to_json
    end

    def get_available_dts
      %w[uk-gaap uk-ifrs ie-gaap ie-ifrs].map do |name| 
        model = DiscoverableTaxonomySet.new(name)
        { id: model.id, name: model.name }
      end.to_json
    end

    private

    def hashify_xml(xml)
      xml.each_with_object({}) { |(k,v), hsh| hsh[k] = v }
    end

    def nodes_for_role(role_links)
      role_links.map do |link|
        link[:locs].map do |k,v|
          {
            id: v["label"],
            parent_id: node_parent(v["label"], link[:arcs]),
            label: node_labels(v["href"])
           }
        end
      end
    end

    def node_parent(id, arcs)
      arcs.values.detect { |arc| arc["to"] == id }&.dig("from") || "root_node"
    end
  end

  $app ||= TaxonomyParser.new
end
