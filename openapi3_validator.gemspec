Gem::Specification.new do |s|
  s.name        = 'openapi3_validator'
  s.version     = '0.0.0'
  s.date        = '2018-06-20'
  s.summary     = "Validate rack response compliance to OpenApi v3"
  # s.description = ""
  s.authors     = ["uchiru"]
  # s.email       = ''
  s.files       = ["lib/openapi3_validator.rb"]
  # s.homepage    =
  # s.license       = 'MIT'
  s.add_runtime_dependency "openapi3_parser", ["~> 0.3.0"]
  s.add_runtime_dependency "json-schema"
  s.add_development_dependency "rspec"
  s.add_development_dependency "rack-test"
end
