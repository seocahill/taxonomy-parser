module TaxonomyParser
  class ElementParser < BaseParser

    class << self

      def parse(current_dts)
        @bucket = Store.instance.data[:elements] = {}
        @tuples = []
        @current_dts = current_dts
        parse_and_store_elements
        associate_tuples if @tuples.any?
      end
      
      def parse_and_store_elements
        files = File.join(__dir__, "/../../dts_assets/#{@current_dts.name}/**/*.xsd")

        Dir.glob(files).grep_v(/(full|main|minimum)/) do |file|
          parsed_nodes = Nokogiri::XML(File.open(file)).search("element")
          parsed_nodes.each do |node|
            parse_schema_node(node)
          end
        end
      end

      private

      def parse_schema_node(node)
        if node.attributes.has_key?("id")
          element = hashify_xml(node)
          store_element(element)

          if node.attributes["substitutionGroup"].value == "xbrli:tuple"
            node.search('element').each do |member|
              @tuples << [element["id"], hashify_xml(member)]
            end
          end
        end
      end

      def store_element(node)
        @bucket[node["id"]] = Element.new(
          node["id"], 
          @current_dts.id, 
          node["name"], 
          node["type"], 
          node["substitutionGroup"], 
          node["periodType"], 
          node["abstract"], 
          node["nillable"]
        )
      end

      def associate_tuples
        @tuples.each do |group_id, tuple|
          id = tuple["ref"].gsub(":", "_")
          model = @bucket[id]
          model.tuple_id = group_id
          model.max_occurs = tuple["maxOccurs"]
          model.min_occurs = tuple["minOccurs"]
        end
      end
    end
  end
end
