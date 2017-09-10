module TaxonomyParser
  module ReferenceParser
    #
    # each node has the element_id which corresponds to a reference loc
    # each reference loc is linked to a reference via a reference arc
    # each node belongs to element
    # each element has many references
    # each reference has a standard and a documentation reference
    # each reference object should have an element_id == loc.from and a body = loc.to.reference
    #

    def parse_reference_linkbases
      references = []
      reference_id = 0
      @store[:references] = {}
      Dir.glob(File.join(__dir__, "/../../dts_assets/#{@current_dts.name}/**/*.xml")).grep(/reference/) do |file|
        parsed_file = Nokogiri::XML(File.open(file))
        parsed_file.search('referenceLink').each do |link|
          nodes = {}
          link.search('referenceArc', 'reference', ).each do |node|
            if node.name == 'referenceArc'
              element = @store[:elements][node.attributes['from'].value]
              reference_id += 1
              reference = Reference.new(reference_id, element)
              raise if element.reference
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
            @store[:references][node.id] = node
          end
        end
      end
    end
  end
end