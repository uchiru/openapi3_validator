require 'openapi3_validator'
require 'json-schema'

RSpec::Matchers.define :match_api_spec do |status|
  match do |actual|
    res  = actual
    req  = actual.respond_to?(:request) ? actual.request : last_request
    meth      = req.request_method.downcase
    path_spec = Openapi3Validator.spec.paths.match(req.path) || raise(Openapi3Validator::Errors::PathNotFound, "Can't find path spec for #{meth} #{req.path}")
    meth_spec = path_spec.public_send(meth) || raise(Openapi3Validator::Errors::MethodNotFound, "Can't find method spec for #{meth} #{req.path}")
    resp_spec = meth_spec.responses.find { |k, _| k == status.to_s }&.last || raise(Openapi3Validator::Errors::StatusDoesNotMatch, "Can't find matching path in spec: #{meth} #{req.path} -> #{status}")
    res.status == status.to_i || raise(Openapi3Validator::Errors::StatusDoesNotMatch, "Expected: #{status.inspect}\nGot: #{res.status.inspect}")

    schema = resp_spec.content['application/json']&.schema&.to_h
    if schema
      begin
        JSON::Validator.validate!(schema, res.body)
      rescue JSON::Schema::ValidationError => e
        require 'pp'
        e.message += "\nSchema: #{schema.pretty_inspect}"
        raise e
      end
    else
      res.body.size.zero? || raise(ExpectedNoContent, "#{meth} #{req.path} -> #{status}\nGot body: #{body.inspect}")
    end
  end
end
