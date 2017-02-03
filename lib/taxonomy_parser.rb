require_relative 'parsers/schema'
require_relative 'parsers/presentation'
require_relative 'parsers/label'
require_relative 'parsers/reference'

module TaxonomyParser
  class TaxonomyParser
    include SchemaParser
    include PresentationParser
    include ReferenceParser
    include LabelParser

    def initialize # (lang=en, dts=uk-gaap)
      @networks = {}
      @network_locations = {}
      @links = Hash.new { |hash, key| hash[key] = {} }
      @checksums = {}
      @concepts, @role_types = parse_dts_schemas
      @label_items = parse_label_linkbases
      @reference_items = parse_reference_linkbases
      parse_definition_and_presentation_linkbases
    end

    def graph
      @networks.to_json
    end

    def menu(network)
      items = network ? @networks.select { |k,v| v[:networks].include?(network) } : @networks
      items.map { |k,v| v[:label] }.sort_by { |i| i.split().first.to_i }.to_json
    end

    def links
      @links.to_json
    end

    def checksums
      @links.each do |k,v|
        check = @checksums[k]
        check[:locs][:parsed] = v[:locs].count
        check[:arcs][:parsed] = v[:arcs].count
        check[:diff] = check[:locs].values.inject(0, :+) % 2 + check[:arcs].values.inject(0, :+) % 2
      end
      @checksums.reject { |k,v| v[:diff] == 0 }.to_json
    end

    private

    def hashify_xml(xml)
      xml.each_with_object({}) { |(k,v), hsh| hsh[k] = v }
    end
  end

  $app ||= TaxonomyParser.new
end
