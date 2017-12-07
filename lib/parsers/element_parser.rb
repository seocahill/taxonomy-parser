module TaxonomyParser
  class ElementParser < BaseParser

    class << self

      def parse(current_dts)
        @bucket = Store.instance.get_data[:elements] = {}
        @current_dts = current_dts
        concepts, tuples = parse_dts_schemas
        store_elements(concepts, tuples)
      end
      
      def parse_dts_schemas
        concepts = {}
        tuples = []
        files = File.join(__dir__, "/../../dts_assets/#{@current_dts.name}/**/*.xsd")

        Dir.glob(files).grep_v(/(full|main|minimum)/) do |file|
          parsed_file = Nokogiri::XML(File.open(file))
          parsed_nodes = parsed_file.search("element")
          parsed_nodes.each do |node|
            parse_schema_node(concepts, tuples, node)
          end
        end

        [concepts, tuples]
      end

      def store_elements(concepts, tuples)
        concepts.each do |id, v|
          @bucket[id] = Element.new(
            id, 
            @current_dts.id, 
            v["name"], 
            v["type"], 
            v["substitutionGroup"], 
            v["periodType"], 
            v["abstract"], 
            v["nillable"]
          )
        end

        tuples.each do |tuple|
          group_id, attrs = tuple
          id = attrs["ref"].gsub(":", "_")
          model = @bucket[id]
          model.tuple_id = group_id
          model.max_occurs = attrs["maxOccurs"]
          model.min_occurs = attrs["minOccurs"]
        end
      end

      private

      def parse_schema_node(concepts, tuples, node)
        if node.attributes.has_key?("id")
          id = node.attributes["id"].value
          concepts[id] = hashify_xml(node)

          if node.attributes["substitutionGroup"].value == "xbrli:tuple"
            node.search('element').each do |member|
              tuples << [id, hashify_xml(member)]
            end
          end
        end
      end
    end
  end
end
