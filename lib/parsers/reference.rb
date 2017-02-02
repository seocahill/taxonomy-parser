module ReferenceParser
  def parse_reference_linkbases
    entries = { locs: {}, links: {}, resources: {} }
    Dir.glob("dts_assets/uk-gaap/**/*.xml").grep(/reference/) do |file|
      parsed_file = Nokogiri::XML(File.open(file))
      parsed_file.search('loc', 'referenceArc', 'reference').each do |item|
        case item.name
        when "loc"
          entries[:locs][item.attributes["label"].value] = hashify_xml(item)
        when "referenceArc"
          entries[:links][item.attributes["from"].value] = hashify_xml(item)
        when "reference"
          resource = entries[:resources][item.attributes["label"].value] ||= {}
          attrs = resource[item.attributes["role"].value] = {}
          item.elements.each { |element| attrs[element.name] = element.text }
        end
      end
    end
    entries
  end
end
