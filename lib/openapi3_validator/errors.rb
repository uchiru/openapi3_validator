class Openapi3Validator
  class Error < RuntimeError; end
  module Errors
    class PathNotFound < Error; end
    class MethodNotFound < Error; end
    class StatusNotFound < Error; end
    class StatusDoesNotMatch < Error; end
    class ContentTypeNotFound < Error; end
    class ExpectedNoContent < Error; end
    class SchemaValidationFailed < Error; end
  end
end
