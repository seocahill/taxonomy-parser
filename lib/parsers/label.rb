module TaxonomyParser
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
      label_id = 0
      @store[:labels] = {}
      
      Dir.glob(File.join(__dir__, "/../../dts_assets/#{@current_dts.name}/**/*.xml")).grep(/label/) do |file|
        parsed_file = Nokogiri::XML(File.open(file))
        parsed_file.search('labelLink').each do |link|
          nodes = {}

          link.search('labelArc', 'label', ).each do |node|
            if node.name == 'labelArc'
              element = @store[:elements][node.attributes['from'].value]
              label_id += 1
              label = Label.new(label_id, element)
              element.labels << label
              nodes[node.attributes['to'].value] = label
            else
              label = nodes[node.attributes['label'].value]
              label_type = node.attributes['role'] ? node.attributes['role'].value.split('/').last : "label"
              label_type = snake_case(label_type)
              label.send("#{label_type}=", node.text)
              check_if_invertible(node, label, label_type)
            end
          end

          nodes.values.each do |node|
            @store[:labels][node.id] = node
          end
        end
      end
    end

    # There are a few false positives this way but pretty obscure can tweak later with black or whitelist
    def check_if_invertible(node, label, label_type)
      if (node.text =~ /\(.*\)/) && (label.element.item_type == "xbrli:monetaryItemType") && (label_type == "label")
        label.element.invertible = true
      end
    end

    def snake_case(str)
      return str.downcase if str.match(/\A[A-Z]+\z/)
      str.gsub(/([A-Z]+)([A-Z][a-z])/, '\1_\2').
      gsub(/([a-z])([A-Z])/, '\1_\2').
      downcase
    end
  end
end