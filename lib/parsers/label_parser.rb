module TaxonomyParser
  class LabelParser < BaseParser

    class << self

      def parse(current_dts)
        @id = 1
        @bucket = Store.instance.data[:labels] = {}
        
        Dir.glob(File.join(__dir__, "/../../dts_assets/#{current_dts.name}/**/*.xml")).grep(/label/) do |file|
          linkbase = Nokogiri::XML(File.open(file))
          process_linkbase(linkbase)
        end
      end

      def process_linkbase(parsed_file)
        parsed_file.search('labelLink').each do |link|
          nodes = {}
          link.search('labelArc', 'label', ).each do |node|
            if node.name == 'labelArc'
              nodes[node.attributes['to'].value] = add_new_label(node)
            else
              label = nodes[node.attributes['label'].value]
              update_label(label, node)
            end
          end
        end
      end

      def add_new_label(node)
        element = Store.instance.data[:elements][node.attributes['from'].value]
        label = Label.new(@id, element)
        element.labels << label
        @bucket[@id] = label
        @id += 1
        label
      end

      def update_label(label, node)
        label_type = node.attributes['role'] ? node.attributes['role'].value.split('/').last : "label"
        label_type = snake_case(label_type)
        label.send("#{label_type}=", node.text)
        check_if_invertible(node, label, label_type)
      end

      # There are a few false positives this way but pretty obscure can tweak later with black or whitelist
      def check_if_invertible(node, label, label_type)
        if (node.text =~ /\(.*\)/) && (label.element.item_type == "xbrli:monetaryItemType") && (label_type == "label")
          label.element.invertible = true
        end
      end
    end
  end
end