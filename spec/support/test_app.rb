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
    when '/foo'
      case env.fetch('QUERY_STRING')
      when 'mode=422'
        [422, { 'Content-Type' => 'application/json; charset=utf8' }, ['{"error": "something wrong"}']]
      when 'mode=broken_body'
        [200, { 'Content-Type' => 'application/json; charset=utf8' }, ['{"items":']]
      else
        [200, { 'Content-Type' => 'application/json; charset=utf8' }, ['{"items": []}']]
      end
    when '/pets'
      [201, { 'Content-Type' => 'application/json' }, ['']]
    else
      [404, { 'Content-Type' => 'text/plain'}, []]
    end
  end
end

