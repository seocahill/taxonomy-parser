module TaxonomyParser
  class BaseParser
    def self.hashify_xml(xml)
      xml.each_with_object({}) { |(k,v), hsh| hsh[k] = v }
    end
  end
end