require 'spec_helper'

describe Openapi3Validator do
  include Rack::Test::Methods

  describe 'config' do
    let(:path) { File.expand_path('../support/openapi.yml', __FILE__) }
    describe 'spec=' do
      it 'accepts data string' do
        require 'yaml'
        Openapi3Validator.config.spec = File.read(path)
      end
      it 'accepts uri  string' do
        expect do
        Openapi3Validator.config.spec = 'https://localhost:1'
        end.to raise_error Openapi3Parser::Error::InaccessibleInput
      end
      it 'accepts path string' do
        Openapi3Validator.config.spec = path
      end
      it 'accepts hash' do
        Openapi3Validator.config.spec = YAML.load(File.read(path))
      end
      it 'accepts parsed' do
        Openapi3Validator.config.spec = Openapi3Parser.load_file(path)
      end
    end
  end

  describe '.validate' do
    it 'passes if request/response are ok' do
      get '/'
      expect do
        Openapi3Validator.validate(last_request, last_response)
      end.not_to raise_error
      get '/complex_content_type'
      expect do
        Openapi3Validator.validate(last_request, last_response)
      end.not_to raise_error
    end
    it 'passes if request/response are ok with query' do
      get '/?query=foo'
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
    it 'fails if no such content-type found in spec' do
      get '/bad_type'
      expect do
        Openapi3Validator.validate(last_request, last_response)
      end.to raise_error(Openapi3Validator::Errors::UnexpectedContentType)
    end
    it 'fails if empty content-type found and content is present', :focus do
      get '/no_content'
      expect do
        Openapi3Validator.validate(last_request, last_response)
      end.to raise_error(Openapi3Validator::Errors::ExpectedNoContent)
    end
    it 'passes if non-empty content-type found with no schema and content is present' do
      get '/content_and_no_schema'
      expect do
        Openapi3Validator.validate(last_request, last_response)
      end.not_to raise_error
    end
    it 'fails if schema is invalid' do
      get '/bad_schema'
      expect do
        Openapi3Validator.validate(last_request, last_response)
      end.to raise_error(Openapi3Validator::Errors::SchemaValidationFailed)
    end
    it 'fails if body is broken' do
      get '/foo?mode=broken_body'
      expect do
        Openapi3Validator.validate(last_request, last_response)
      end.to raise_error(Openapi3Validator::Errors::SchemaValidationFailed)
    end

    describe 'request validation' do
      it 'passes if request is ok' do
        post '/pets', JSON.dump(pet: {name: "Bobby"}), {
          'HTTP_ACCEPT' => 'application/json',
          'CONTENT_TYPE' => 'application/json'
        }
        expect do
          p last_response
          Openapi3Validator.validate(last_request, last_response)
        end.not_to raise_error
      end

      it 'failed if request is failed' do
        post '/pets', JSON.dump(pet: {name: "Bobby"}), {
          'HTTP_ACCEPT' => 'application/json',
          'CONTENT_TYPE' => 'application/json'
        }
        expect do
          Openapi3Validator.validate(last_request, last_response)
        end.to raise_error(Openapi3Validator::Errors::RequestValidationFailed)
      end
    end
  end
end
