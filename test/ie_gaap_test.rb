require_relative './test_helper'

class IeGaapTest < MiniTest::Test
  include Rack::Test::Methods
  include TaxonomyParser::TestHelper

  def app
    TaxonomyParser::Base
  end
  
  def test_date_directors_signing_report_dimensions
    skip "todo"
    # http://localhost:4200/api/v1/elements/uk-direp_DateSigningDirectorsReport
    # should return basic hypercube but returing empty at the moment why?
  end
  
end