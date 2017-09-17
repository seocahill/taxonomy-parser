module TaxonomyParser
  class BaseSerializer
    include JSONAPI::Serializer
    
    def base_url
      "/api/v1"
    end
  end
end