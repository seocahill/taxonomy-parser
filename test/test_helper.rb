module TaxonomyParser
  module TestHelper

    def jsonapi_data
      JSON.parse(last_response.body)["data"]
    end

    def jsonapi_data_includes(attr, required)
      actual = jsonapi_data.map { |model| model["attributes"][attr] }
      (required - actual).empty?
    end
  end
end