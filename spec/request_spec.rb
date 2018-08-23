require 'spec_helper'

def app
  lambda do |env|
    case env.fetch('PATH_INFO')
    when '/'
      [200, { 'Content-Type' => 'application/json' }, ['{"foo": "bar"}']]
    when %r{/entities/[0-9]+}
      [200, { 'Content-Type' => 'application/json' }, ['{"entity": {"id": 111}}']]
    when '/bad_status'
      [418, { 'Content-Type' => 'application/json' }, ['{}']]
    when '/bad_type'
      [200, { 'Content-Type' => 'application/json' }, ['{}']]
    when '/bad_schema'
      [200, { 'Content-Type' => 'application/json' }, ['{"bar": []}']]
    when '/no_content'
      [200, { 'Content-Type' => 'text/plain' }, ['should not be here']]
    when '/content_and_no_schema'
      [200, { 'Content-Type' => 'text/plain' }, ['its okay']]
    when '/complex_content_type'
      [200, { 'Content-Type' => 'application/json; charset=utf8' }, ['{"foo": "bar"}']]
    when '/with_default'
      [422, { 'Content-Type' => 'application/json; charset=utf8' }, ['{"error": "something wrong"}']]
    else
      [404, { 'Content-Type' => 'text/plain'}, []]
    end
  end
end

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
    get '/with_default'
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
