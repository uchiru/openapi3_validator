# OpenAPI3 Validator

Validate rack response compliance to OpenApi v3

## Usage

``` ruby
  validator = Openapi3Validator.tap { |v| v.config.spec = "#{BACKEND_URL}/#{SPEC_PATH}" }
  req = OpenStruct.new(request_method: "GET", path: "/", content_type: "default", body: "") 
  res = OpenStruct.new(status:  200, body: '{"foo": "bar"}', headers: {'content-type' => 'application/json'})
  validator.validate(req, res)
```
