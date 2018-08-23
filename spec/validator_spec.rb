require 'spec_helper'

describe Openapi3Validator do
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
    it 'is ok when path, status, content-type and schema are ok' do
      req = OpenStruct.new(request_method: "GET", path: "/", content_type: "default", body: "") 
      res = OpenStruct.new(status: 200, body: '{"foo": "bar"}', headers: {'content-type' => 'application/json'})

      expect do
        Openapi3Validator.validate(req, res)
      end.not_to raise_error
    end

    it 'is ok when complex content-type' do
      req = OpenStruct.new(request_method: "GET", path: "/complex_content_type", content_type: "default", body: "") 
      res = OpenStruct.new(status: 200, body: '{"foo": "bar"}', headers: {'content-type' => 'application/json; charset=utf8'})

      expect do
        Openapi3Validator.validate(req, res)
      end.not_to raise_error
    end

    it 'is ok with status matched by default' do
      req = OpenStruct.new(request_method: "GET", path: "/foo", content_type: "default", body: "") 
      res = OpenStruct.new(status: 422, body: '{"error": "something wrong"}', headers: {'content-type' => 'application/json'})

      expect do
        Openapi3Validator.validate(req, res)
      end.not_to raise_error
    end

    it 'fails when status does not match' do
      req = OpenStruct.new(request_method: "GET", path: "/nonsense", content_type: "default", body: "") 
      res = OpenStruct.new(status: 404, body: '', headers: {'content-type' => 'application/json'})

      expect do
        Openapi3Validator.validate(req, res)
      end.to raise_error(Openapi3Validator::Errors::PathNotFound)
    end

    it 'fails if no such method found in spec' do
      req = OpenStruct.new(request_method: "POST", path: "/", content_type: "application/json", body: "{}") 
      res = OpenStruct.new(status: 201, body: '', headers: {'content-type' => 'application/json'})

      expect do
        Openapi3Validator.validate(req, res)
      end.to raise_error(Openapi3Validator::Errors::MethodNotFound)
    end

    it 'fails if no such reponse status found in spec' do
      req = OpenStruct.new(request_method: "GET", path: "/bad_status", content_type: "default", body: "") 
      res = OpenStruct.new(status: 418, body: '', headers: {'content-type' => 'application/json'})
      expect do
        Openapi3Validator.validate(req, res)
      end.to raise_error(Openapi3Validator::Errors::StatusNotFound)
    end

    it 'fails if no such content-type found in spec' do
      req = OpenStruct.new(request_method: "GET", path: "/bad_type", content_type: "default", body: "") 
      res = OpenStruct.new(status: 200, body: '', headers: {'content-type' => 'application/json'})
      expect do
        Openapi3Validator.validate(req, res)
      end.to raise_error(Openapi3Validator::Errors::UnexpectedContentType)
    end

    it 'fails if empty content-type found and content is present', :focus do
      req = OpenStruct.new(request_method: "GET", path: "/no_content", content_type: "default", body: "") 
      res = OpenStruct.new(status: 200, body: 'should not be here', headers: {'content-type' => 'text/plain'})
      expect do
        Openapi3Validator.validate(req, res)
      end.to raise_error(Openapi3Validator::Errors::ExpectedNoContent)
    end

    it 'passes if non-empty content-type found with no schema and content is present' do
      req = OpenStruct.new(request_method: "GET", path: "/content_and_no_schema", content_type: "default", body: "") 
      res = OpenStruct.new(status: 200, body: 'its ok', headers: {'content-type' => 'text/plain'})
      expect do
        Openapi3Validator.validate(req, res)
      end.not_to raise_error
    end

    it 'fails if schema is invalid' do
      req = OpenStruct.new(request_method: "GET", path: "/bad_schema", content_type: "default", body: "") 
      res = OpenStruct.new(status: 200, body: '{"bar": []}', headers: {'content-type' => 'application/json'})

      expect do
        Openapi3Validator.validate(req, res)
      end.to raise_error(Openapi3Validator::Errors::SchemaValidationFailed)
    end

    it 'fails if body is broken' do
      req = OpenStruct.new(request_method: "GET", path: "/foo", content_type: "default", body: "") 
      res = OpenStruct.new(status: 200, body: '{"items":', headers: {'content-type' => 'application/json'})
      expect do
        Openapi3Validator.validate(req, res)
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
