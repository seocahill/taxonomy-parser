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

      def snake_case(str)
        return str.downcase if str.match(/\A[A-Z]+\z/)
        str.gsub(/([A-Z]+)([A-Z][a-z])/, '\1_\2').
        gsub(/([a-z])([A-Z])/, '\1_\2').
        downcase
      end
    end
  end
end