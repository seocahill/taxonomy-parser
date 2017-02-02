module LabelParser
  def parse_label_linkbases
    entries = { locs: {}, links: {}, resources: {} }
    Dir.glob("dts_assets/uk-gaap/**/*.xml").grep(/label/) do |file|
      parsed_file = Nokogiri::XML(File.open(file))
      parsed_file.search('loc', 'labelArc', 'label').each do |item|
        case item.name
        when "loc"
          entries[:locs][item.attributes["label"].value] = hashify_xml(item)
        when "labelArc"
          entries[:links][item.attributes["from"].value] = hashify_xml(item)
        when "label"
          resource = entries[:resources][item.attributes["label"].value] ||= {}
          resource[item.attributes["role"].value] = item.text
        end
      end
    end
    entries
  end
end
