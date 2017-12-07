module TaxonomyParser
  class RoleTypeParser < BaseParser

    class << self

      def parse(current_dts)
        @id = 1
        @bucket = Store.instance.get_data[:role_types] = {}
        @current_dts = current_dts
        parse_and_store_role_type_nodes
        add_role_types_current_dts
      end
      
      def parse_and_store_role_type_nodes
        files = File.join(__dir__, "/../../dts_assets/#{@current_dts.name}/**/*.xsd")

        Dir.glob(files).grep_v(/(full|main|minimum)/) do |file|
          role_type_nodes = Nokogiri::XML(File.open(file)).search("link|roleType")
          role_type_nodes.map do |node|
            store_role_type(node)
          end
        end
      end

      def store_role_type(node)
        child_attributes = node.children.each_with_object({}) do |child, obj|
          obj[child.name] = child.text
        end

        model = RoleType.new(
          @id, 
          @current_dts.id, 
          child_attributes["definition"], 
          node.attributes["roleURI"].value, 
          child_attributes["usedOn"]
        ) 
        @bucket[@id] = model
        index(:role_uri)[model.role_uri] = model.id
        @id += 1
      end

      def add_role_types_current_dts
        @current_dts.role_types = @bucket.values
          .select { |item| item.network == "link:presentationLink" }
          .sort_by { |item| item.order }
      end
    end
  end
end
