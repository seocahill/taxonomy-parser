module TaxonomyParser
  module DTSParser
    class << self

      def parse
        # If no default is set use uk gaap with irish extension.
        default_dts = ENV.fetch("DTS", "ie-gaap")
        dts_path = File.join(__dir__, "../../dts_assets")

        # exclude . .. .DS_Store etc
        source_dts_files = Dir.entries(dts_path).reject do |file| 
          file[0] == '.' 
        end
        
        # sort for predictable index
        source_dts_files.sort.each_with_object({}).with_index do |(name, parsed_dts), index| 
          model = DiscoverableTaxonomySet.new(index, name)
          # ApplicationController.discoverable_taxonomy_set(model.id) if name == default_dts
          parsed_dts[model.id] = model
        end
      end
    end
  end
end