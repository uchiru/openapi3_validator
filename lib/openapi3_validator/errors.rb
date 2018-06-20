class Openapi3Validator
  module Errors
    class PathNotFound < RuntimeError; end
    class MethodNotFound < RuntimeError; end
    class StatusDoesNotMatch < RuntimeError; end
    class ContentTypeNotFound < RuntimeError; end
    class ExpectedNoContent < RuntimeError; end
  end
end
