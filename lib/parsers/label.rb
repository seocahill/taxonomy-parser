module LabelParser
  #
  # each node has the element_id which corresponds to a label loc
  # each label loc is linked to a label via a label arc
  # each node belongs to element
  # each element has many labels
  # each label has a standard and a documentation label
  # each label object should have an element_id == loc.from and a body = loc.to.label
  #

  def parse_label_linkbases
    labels = []
    Dir.glob("dts_assets/uk-gaap/**/*.xml").grep(/label/) do |file|
      parsed_file = Nokogiri::XML(File.open(file))
      parsed_file.search('labelLink').each do |link|
        nodes = {}
        link.search('labelArc', 'label', ).each do |element|
          if element.name == 'labelArc'
            nodes[element.attributes['to'].value] = {
              id: SecureRandom.uuid,
              element_id: element.attributes['from'].value
            }
          else
            label = nodes[element.attributes['label'].value]
            label[element.attributes['role'].value.split('/').last] = element.text
          end
        end
        labels << nodes.values
      end
    end
    labels.flatten
  end

  def properties(element)
    element.elements.each_with_object({}) do |element, object|
      object[element.name] = element.text
    end
  end
end
