# frozen_string_literal: true

require 'openapi3_parser'
require 'openapi3_validator/errors'

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
    meth      = req.env['REQUEST_METHOD'].downcase
    path_spec = Openapi3Validator.spec.paths.match(req.path) || raise(Openapi3Validator::Errors::PathNotFound, "Can't find path spec for #{meth} #{req.path}")
    meth_spec = path_spec.public_send(meth) || raise(Openapi3Validator::Errors::MethodNotFound, "Can't find method spec for #{meth} #{req.path}")
    resp_spec = meth_spec.responses.find { |k, _| k == res.status.to_s }&.last || raise(Openapi3Validator::Errors::StatusNotFound, "Can't find matching status in spec: #{meth} #{req.path} -> #{res.status}")

    schema = resp_spec.content['application/json']&.schema&.to_h
    if schema
      begin
        JSON::Validator.validate!(schema, res.body)
      rescue JSON::Schema::ValidationError => e
        require 'pp'
        e.message += "\nSchema: #{schema.pretty_inspect}"
        raise e
      end
    else
      res.body.size.zero? || raise(Openapi3Validator::Errors::ExpectedNoContent, "#{meth} #{req.path} -> #{res.status}\nGot body: #{res.body.inspect}")
    end
  end
end
