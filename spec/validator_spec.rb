require 'spec_helper'

describe Openapi3Validator do
  include Rack::Test::Methods

  describe '.validate' do
    it 'passes if request/response are ok' do
      get '/'
      expect do
        Openapi3Validator.validate(last_request, last_response)
      end.not_to raise_error
    end
    it 'fails if no such path found in spec' do
      get '/nonsense'
      expect do
        Openapi3Validator.validate(last_request, last_response)
      end.to raise_error(Openapi3Validator::Errors::PathNotFound)
    end
    it 'fails if no such method found in spec' do
      post '/'
      expect do
        Openapi3Validator.validate(last_request, last_response)
      end.to raise_error(Openapi3Validator::Errors::MethodNotFound)
    end
    it 'fails if no such reponse status found in spec' do
      get '/bad_status'
      expect do
        Openapi3Validator.validate(last_request, last_response)
      end.to raise_error(Openapi3Validator::Errors::StatusNotFound)
    end
    it 'fails if no such content-type found in spec and content is present' do
      get '/bad_type'
      expect do
        Openapi3Validator.validate(last_request, last_response)
      end.to raise_error(Openapi3Validator::Errors::ExpectedNoContent)
    end
    it 'fails if schema is invalid' do
      get '/bad_schema'
      expect do
        Openapi3Validator.validate(last_request, last_response)
      end.to raise_error(JSON::Schema::ValidationError)
    end
  end
end
