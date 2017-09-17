module TaxonomyParser
  class BaseSerializer
    include JSONAPI::Serializer
    
    def base_url
      "/api/v1"
    end

    def format_name(attribute_name)
      attribute_name.to_s.gsub("-", "_")
    end
  end
end