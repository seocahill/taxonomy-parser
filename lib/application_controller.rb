module TaxonomyParser
  class ApplicationController 

    class << self

      def discoverable_taxonomy_sets
        JSONAPI::Serializer.serialize(Store.instance.dts.values, is_collection: true).to_json
      end

      def discoverable_taxonomy_set(id)
        current_dts = Store.instance.dts[id.to_i]
        parse_current_dts(current_dts) if current_dts.role_types.nil?
        JSONAPI::Serializer.serialize(current_dts, include: ['role-types']).to_json
      end

      def role_types(params)
        role_types = Store.instance.get_data[:role_types].values_at(*params["filter"]["id"].split(',').map(&:to_i))
        JSONAPI::Serializer.serialize(role_types, is_collection: true).to_json
      end

      def role_type(id)
        role_type = Store.instance.get_data[:role_types][id.to_i]
        JSONAPI::Serializer.serialize(role_type).to_json
      end

      def role_type_presentation_nodes(id)
        role_type = Store.instance.get_data[:role_types][id.to_i]
        JSONAPI::Serializer.serialize(role_type.presentation_nodes, is_collection: true).to_json
      end

      def element(id)
        element = Store.instance.get_data[:elements][id]
        JSONAPI::Serializer.serialize(element, include: ['presentation-nodes', 'dimension-nodes', 'labels']).to_json
      end

      def element_presentation_nodes(id)
        element = Store.instance.get_data[:elements][id]
        JSONAPI::Serializer.serialize(element.presentation_nodes, is_collection: true, include: ['role-type']).to_json
      end

      def element_dimension_nodes(id)
        element = Store.instance.get_data[:elements][id]
        JSONAPI::Serializer.serialize(element.dimension_nodes, is_collection: true).to_json
      end

      def presentation_nodes(params)
        presentation_nodes = if params.dig('filter', 'id')
          Store.instance.get_data[:presentation_nodes].values_at(*params["filter"]["id"].split(',').map(&:to_i))
        else 
          Store.instance.get_data[:presentation_nodes].values
        end
        presentation_nodes.each { |node| element = node.element }
        JSONAPI::Serializer.serialize(presentation_nodes, include: ['element.dimension-nodes', 'element.labels'], is_collection: true).to_json
      end

      def presentation_node(id)
        presentation_node = Store.instance.get_data[:presentation_nodes][id.to_i]
        element = presentation_node.element
        JSONAPI::Serializer.serialize(presentation_node, include: ['element.dimension-nodes', 'element.labels']).to_json
      end

      def presentation_node_role_type(id)
        presentation_node = Store.instance.get_data[:presentation_nodes][id.to_i]
        role_type = presentation_node.role_type
        JSONAPI::Serializer.serialize(role_type).to_json
      end

      def dimension_node(id)
        dimension_node = Store.instance.get_data[:dimension_nodes][id.to_i]
        JSONAPI::Serializer.serialize(dimension_node, include: ['element']).to_json
      end

      def dimension_nodes(params)
        dimension_nodes = Store.instance.get_data[:dimension_nodes].values_at(*params["filter"]["id"].split(',').map(&:to_i))
        JSONAPI::Serializer.serialize(dimension_nodes, is_collection: true).to_json
      end

      def dimension_node_element(id)
        dimension_node = Store.instance.get_data[:dimension_nodes][id.to_i]
        JSONAPI::Serializer.serialize(dimension_node.element).to_json
      end

      def label(id)
        label = Store.instance.get_data[:labels][id.to_i]
        JSONAPI::Serializer.serialize(label).to_json
      end

      def reference(id)
        reference = Store.instance.get_data[:references][id.to_i]
        JSONAPI::Serializer.serialize(reference).to_json
      end

      private

      def parse_current_dts(current_dts)
        SchemaParser.parse(current_dts)
        PresentationParser.parse(current_dts)
        DimensionParser.parse(current_dts)
        LabelParser.parse(current_dts)
        ReferenceParser.parse(current_dts)
      end
    end
  end
end
