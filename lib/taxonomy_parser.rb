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
      @links = {}
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

    def role_types(role)
      roleURI = "http://www.xbrl.org/uk/role/" + role
      @networks[roleURI].to_json
    end

    def checksums
      @links.each do |k,v|
        check = @checksums[k]
        check[:locs][:parsed] = v.inject(0) { |m,i| m += i[:locs].count }
        check[:arcs][:parsed] = v.inject(0) { |m,i| m += i[:arcs].count }
        check[:diff] = check[:arcs][:xml] - check[:arcs][:parsed]
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
