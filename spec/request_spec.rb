require 'spec_helper'

describe 'Request validation' do
  include Rack::Test::Methods

  it 'is ok when path, status, content-type and schema are ok' do
    get '/'
    expect(last_response).to match_api_spec(200)
  end

  it 'is ok when path, status, content-type and schema are ok, and with query string' do
    get '/?foo=bar'
    expect(last_response).to match_api_spec(200)
    get '/entities/111?query=bar'
    expect(last_response).to match_api_spec(200)
  end

  it 'is ok with compound path' do
    get '/entities/111'
    expect(last_response).to match_api_spec(200)
  end

  it 'is ok with status matched by default' do
    get '/foo?mode=422'
    expect(last_response).to match_api_spec(422)
  end

  it 'fails when status does not match' do
    get '/nonsense'
    expect(last_response.status).to eq 404
    expect do
      expect(last_response).to match_api_spec(200)
    end.to raise_error(Openapi3Validator::Errors::PathNotFound)
  end
end
