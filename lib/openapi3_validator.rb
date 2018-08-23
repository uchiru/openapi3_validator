# frozen_string_literal: true

require 'openapi3_parser'
require 'openapi3_validator/errors'
require 'json-schema'

# TODO: refinements

module Openapi3Parser::Nodes
  module ToHash
    def to_h
      case node_data
      when ::Hash
        res = node_data
          .reject { |_, v| v.nil? }
          .transform_values(&method(:_transform_value))
        res['type'] = [res['type'], 'null'] if res['type'] && res['nullable']
        res['properties']&.empty? && res.delete('properties')
        res['dependencies']&.any? && res.delete('additionalProperties')
        res['dependencies']&.empty? && res.delete('dependencies')
        res['type'] != 'object' && res.delete('additionalProperties')
        res
      when ::Array
        node_data
      end
    end

    def _transform_value(val)
      case val
      when Map, Schema
        val.to_h
      when Array
        val.map(&method(:_transform_value))
      else
        val
      end
    end
  end

  class Map
    include ToHash

    def empty?
      node_data.empty?
    end
  end

  class Array
    include ToHash
  end

  class Schema
    include ToHash
  end

  class Paths
    def match(path)
      path_segs = path.split('/')
      node_data.find do |key, _|
        spec_segs = key.split('/').map { |seg| seg.include?('{') ? %r{[^/]+} : seg }
        next false unless path_segs.size == spec_segs.size
        spec_segs.zip(path_segs).all? { |a, b| a === b }
      end&.last
    end
  end
end

module Openapi3Parser::NodeFactories
  class Schema
    field 'dependencies', factory: :properties_factory
  end
end

class Openapi3Validator
  def self.config
    @config ||=
      begin
        Struct.new(:spec) do
          def spec=(spec)
            @spec = spec_from_arbitrary_input(spec).tap(&:valid?).freeze
          end

          def spec
            @spec || raise('Specify spec_path: Openapi3Validator.config.spec_path = ')
          end

          private

          def spec_from_arbitrary_input(input)
            case input
            when String
              file = input.size < 4096 && File.exist?(input) rescue nil
              return Openapi3Parser.load_file(input) if file
              uri = input.size < 4096 && URI(input) rescue nil
              return Openapi3Parser.load_url(input) if uri
              Openapi3Parser.load(input)
            when Hash, IO
              Openapi3Parser.load(input)
            when Openapi3Parser::Document
              input
            else
              raise ArgumentError, "Can't use input as a spec!"
            end
          end
        end.new
      end
  end

  def self.spec
    config.spec
  end

  def self.validate(req, res)
    # prepare specs
    meth      = req.request_method.downcase
    path_spec = Openapi3Validator.spec.paths.match(req.path) || raise(Errors::PathNotFound, "Can't find path spec for #{meth} #{req.path}")
    meth_spec = path_spec.public_send(meth) || raise(Errors::MethodNotFound, "Can't find method spec for #{meth} #{req.path}")
    resp_spec = (meth_spec.responses.find { |k, _| k == res.status.to_s } || meth_spec.responses.find { |k, _| k == 'default' })&.last || raise(Errors::StatusNotFound, "Can't find matching status in spec: #{meth} #{req.path} -> #{res.status}")
    req_spec = meth_spec.request_body

    # validate request
    if req_spec && req.content_type == "application/json"
      if req_spec.content && req_spec.content[req.content_type] && req_spec.content[req.content_type].schema
        schema = req_spec.content[req.content_type].schema.to_h
        begin
          JSON::Validator.validate!(schema, JSON.load(req.body))
        rescue JSON::Schema::ValidationError => e
          require 'pp'
          e.message += "\nSchema: #{schema.pretty_inspect}"
          raise Errors::RequestValidationFailed, e.message
        rescue JSON::Schema::UriError => e
          raise Errors::RequestValidationFailed, e.message
        end
      end
    end

    # content empty?
    if resp_spec.content.to_a.empty?
      if res.body.size.zero?
        return
      else
        raise(Errors::ExpectedNoContent, "#{meth} #{req.path} -> #{res.status}\nGot body: #{res.body.inspect}")
      end
    end

    # find schema
    type = (res.headers['Content-Type'] || res.headers['content-type'])&.split(';')&.first
    if !type.nil? && resp_spec.content[type].nil?
      raise(Errors::UnexpectedContentType, "#{meth} #{req.path} -> #{res.status} unexpected content type #{type}")
    end
    content = resp_spec.content[type]
    schema = content&.schema&.to_h
    return unless schema

    # validate response
    begin
      JSON::Validator.validate!(schema, res.body)
    rescue JSON::Schema::ValidationError => e
      require 'pp'
      e.message += "\nSchema: #{schema.pretty_inspect}"
      raise Errors::SchemaValidationFailed, e.message
    rescue JSON::Schema::UriError => e
      raise Errors::SchemaValidationFailed, e.message
    end
  end
end
