module TaxonomyParser
  class ReferenceParser

    class << self

      def parse(current_dts)
        reference_id = 0
        Store.instance.get_data[:references] = {}
        
        Dir.glob(File.join(__dir__, "/../../dts_assets/#{current_dts.name}/**/*.xml")).grep(/reference/) do |file|
          parsed_file = Nokogiri::XML(File.open(file))
          parsed_file.search('referenceLink').each do |link|
            nodes = {}

            link.search('referenceArc', 'reference', ).each do |node|
              if node.name == 'referenceArc'
                element = Store.instance.get_data[:elements][node.attributes['from'].value]
                reference_id += 1
                reference = Reference.new(reference_id, element)
                element.reference = reference
                nodes[node.attributes['to'].value] = reference
              else
                reference = nodes[node.attributes['label'].value]
                reference.reference_data = node.elements.map do |el|
                  Hash[el.name, el.text]
                end
              end
            end

            nodes.values.each do |node|
              Store.instance.get_data[:references][node.id] = node
            end
          end
        end
      end

    end
  end
end