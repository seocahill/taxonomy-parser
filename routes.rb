module TaxonomyParser
  module Routes

    def self.registered(app)
      app.get '/discoverable-taxonomy-sets' do
        content_type :api_json
        ApplicationController.discoverable_taxonomy_sets
      end

      app.get '/discoverable-taxonomy-sets/:id' do
        content_type :api_json
        ApplicationController.discoverable_taxonomy_set(params['id'])
      end

      app.get '/role-types' do
        content_type :api_json
        ApplicationController.role_types(params)
      end

      app.get '/role-types/:id' do
        content_type :api_json
        ApplicationController.role_type(params['id'])
      end

      app.get '/role-types/:id/presentation-nodes' do
        content_type :api_json
        ApplicationController.role_type_presentation_nodes(params['id'])
      end

      app.get '/elements/:id' do
        content_type :api_json
        ApplicationController.element(params['id'])
      end

      app.get '/elements/:id/presentation-nodes' do
        content_type :api_json
        ApplicationController.element_presentation_nodes(params['id'])
      end

      app.get '/elements/:id/dimension-nodes' do
        content_type :api_json
        ApplicationController.element_dimension_nodes(params['id'])
      end

      app.get '/presentation-nodes' do
        content_type :api_json
        ApplicationController.presentation_nodes(params)
      end

      app.get '/presentation-nodes/:id' do
        content_type :api_json
        ApplicationController.presentation_node(params['id'])
      end

      app.get '/presentation-nodes/:id/role-type' do
        content_type :api_json
        ApplicationController.presentation_node_role_type(params['id'])
      end

      app.get '/dimension-nodes/:id' do
        content_type :api_json
        ApplicationController.dimension_node(params['id'])
      end

      app.get '/dimension-nodes' do
        content_type :api_json
        ApplicationController.dimension_nodes(params)
      end

      app.get '/dimension-nodes/:id/element' do
        content_type :api_json
        ApplicationController.dimension_node_element(params['id'])
      end
      
      app.get '/labels/:id' do
        content_type :api_json
        ApplicationController.label(params['id'])
      end

      app.get '/references/:id' do
        content_type :api_json
        ApplicationController.reference(params['id'])
      end
    end
  end
  Sinatra.register Routes
end