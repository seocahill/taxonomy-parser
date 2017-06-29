module ReferenceParser

  #
  # each node has the element_id which corresponds to a ref loc
  # each ref loc is linked to a ref via a ref arc
  # each node belongs to element
  # each element has many references
  # each reference object should have an element_id == loc.from and a body = loc.to.ref
  #

  def parse_reference_linkbases
    references = []
    Dir.glob(File.join(__dir__, "/../../dts_assets/uk-gaap/**/*.xml")).grep(/reference/) do |file|
      parsed_file = Nokogiri::XML(File.open(file))
      parsed_file.search('referenceLink').each do |link|
        arcs = {}
        link.search('referenceArc', 'reference', ).each do |element|
          if element.name == 'referenceArc'
            arcs[element.attributes['to'].value] = element.attributes['from'].value
          else
            locator = arcs[element.attributes['label'].value]
            references << {
              id: SecureRandom.uuid,
              element_id: locator,
              properties: properties(element)
            }
          end
        end
      end
    end
    references
  end

  def properties(element)
    element.elements.each_with_object({}) do |element, object|
      object[element.name] = element.text
    end
  end

end
