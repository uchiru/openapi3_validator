require 'openapi3_validator'
require 'json-schema'

RSpec::Matchers.define :match_api_spec do |status|
  match do |actual|
    res  = actual
    req  = actual.respond_to?(:request) ? actual.request : last_request
    Openapi3Validator.validate(req, res)
    res.status.to_i == status.to_i ||
      raise(Openapi3Validator::Errors::StatusDoesNotMatch, "Expected: #{status.inspect}\nGot: #{res.status.inspect}")
  end
end
