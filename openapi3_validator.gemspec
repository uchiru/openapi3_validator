Gem::Specification.new do |s|
  s.name        = 'openapi3_validator'
  s.version     = File.read(File.expand_path("VERSION", __dir__)).strip
  s.date        = '2018-06-20'
  s.summary     = "Validate rack response compliance to OpenApi v3"
  # s.description = ""
  s.authors     = ["uchiru"]
  # s.email       = ''
  s.files       = ["lib/openapi3_validator.rb"]
  # s.homepage    =
  s.add_runtime_dependency "openapi3_parser", ["~> 0.3.0"]
  s.add_runtime_dependency "json-schema"
  s.add_development_dependency "rspec"
end
