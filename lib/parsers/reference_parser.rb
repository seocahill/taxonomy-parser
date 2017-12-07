module TaxonomyParser
  class ReferenceParser < BaseParser

    class << self

      def parse(current_dts)
        @id = 1
        @bucket = Store.instance.get_data[:references] = {}
        Dir.glob(File.join(__dir__, "/../../dts_assets/#{current_dts.name}/**/*.xml")).grep(/reference/) do |file|
          linkbase = Nokogiri::XML(File.open(file))
          process_linkbase(linkbase)
        end
      end

      def process_linkbase(parsed_file)
        parsed_file.search('referenceLink').each do |link|
          nodes = {}
          link.search('referenceArc', 'reference').each do |node|
            if node.name == 'referenceArc'
              nodes[node.attributes['to'].value] = add_new_reference(node)
            else
              reference = nodes[node.attributes['label'].value]
              update_reference(reference, node)
            end
          end
        end
      end

      def add_new_reference(node)
        element = Store.instance.get_data[:elements][node.attributes['from'].value]
        reference = Reference.new(@id, element)
        element.reference = reference
        @bucket[@id] = reference
        @id += 1
        reference
      end

      def update_reference(reference, node)
        reference.reference_data = node.elements.map do |el|
          Hash[el.name, el.text]
        end
      end
    end
  end
end