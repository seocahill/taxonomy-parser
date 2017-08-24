module TaxonomyParser
  module TestHelper

    def json_data(type="data")
      JSON.parse(last_response.body)[type]
    end

    def json_includes(type="data", attr, required)
      actual = json_data(type).map { |model| model["attributes"][attr] }
      (required - actual).empty?
    end
  end
end