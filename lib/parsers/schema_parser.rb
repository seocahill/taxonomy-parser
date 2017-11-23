module TaxonomyParser
  class SchemaParser

    class << self

      def parse(current_dts)
        @current_dts = current_dts
        concepts, role_types, tuples = parse_dts_schemas
        store_roles(role_types)
        store_elements(concepts, tuples)
      end
      
      def parse_dts_schemas
        concepts = {}
        role_types = {}
        tuples = []
        files = File.join(__dir__, "/../../dts_assets/#{@current_dts.name}/**/*.xsd")

        Dir.glob(files).grep_v(/(full|main|minimum)/) do |file|
          parsed_file = Nokogiri::XML(File.open(file))
          parsed_nodes = parsed_file.search("link|roleType", "element")
          parsed_nodes.each do |node|
            parse_schema_node(concepts, role_types, tuples, node)
          end
        end

        [concepts, role_types, tuples]
      end

      def store_elements(concepts, tuples)
        bucket = Store.instance.get_data[:elements] = {}

        concepts.each do |id, v|
          model = Element.new(
            id, 
            @current_dts.id, 
            v["name"], 
            v["type"], 
            v["substitutionGroup"], 
            v["periodType"], 
            v["abstract"], 
            v["nillable"]
          )
          bucket[model.id] = model
        end

        tuples.each do |tuple|
          group_id, attrs = tuple
          id = attrs["ref"].gsub(":", "_")
          model = bucket[id]
          model.tuple_id = group_id
          model.max_occurs = attrs["maxOccurs"]
          model.min_occurs = attrs["minOccurs"]
        end
      end

      def store_roles(role_types)
        bucket = Store.instance.get_data[:role_types] = {}
        role_id = 0

        role_types.each do |uri, role|
          role_id += 1
          model = RoleType.new(role_id, @current_dts.id, role["definition"], uri, role["usedOn"]) 
          bucket[model.id] = model 
        end

        @current_dts.role_types = Store.instance.get_data[:role_types].values
          .select { |item| item.network == "link:presentationLink" }
          .sort_by { |item| item.order }
      end

      private

      def parse_schema_node(concepts, role_types, tuples, node)

        if node.name == "roleType"
          role_URI = node.attributes["roleURI"].value
          
          role_types[role_URI] = node.children.each_with_object({}) do |child, obj|
            obj[child.name] = child.text
          end
        elsif node.name == "element" && node.attributes.has_key?("id")
          id = node.attributes["id"].value
          concepts[id] = hashify_xml(node)

          if node.attributes["substitutionGroup"].value == "xbrli:tuple"
            node.search('element').each do |member|
              tuples << [id, hashify_xml(member)]
            end
          end
        end
      end

      def hashify_xml(xml)
        xml.each_with_object({}) { |(k,v), hsh| hsh[k] = v }
      end

    end
  end
end
