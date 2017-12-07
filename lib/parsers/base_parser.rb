module TaxonomyParser
  class BaseParser

    class << self 

      def index(column)
        Store.instance.index[column] ||= {}
        Store.instance.index[column]
      end

      def hashify_xml(xml)
        xml.each_with_object({}) { |(k,v), hsh| hsh[k] = v }
      end
    end
  end
end