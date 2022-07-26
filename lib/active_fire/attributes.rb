require 'active_support/core_ext/hash/indifferent_access'

module ActiveFire
  module Attributes
    class Attribute
      attr_reader :type

      def initialize(type:)
        @type = type
        @value = @original = nil
      end

      def write(value)
        if value.nil?
          @value = nil
          return
        end
    
        case type.name
        when "String"
          @value = value.to_s
        when "Integer"
          @value = value.to_i
        end
      end

      def read
        @value
      end
    end

    # class RelationAttribute < Attribute
    #   def initialize(klass)
    #     @klass = klass
    #     @value = @original = nil
    #   end

    #   def write(value)
    #     if value.is_a? Google::Cloud::Firestore::DocumentReference
    #       @original = value
    #       @value = @klass.setup(value.document_id, value.get.data)
    #     elsif value.respond_to? :ref
    #       @original = value.ref
    #       @value = value
    #     else
    #       @value = @original = value
    #     end
    #   end
    # end

    def self.extended(base)
      base.extend ClassMethods
      base.include InstanceMethods
    end

    module ClassMethods
      def __attributes_definition
        @__attributes_definition ||= {}.with_indifferent_access
      end

      # def has_one(name, options = {})
      #   name = name.to_s
      #   options = options.with_indifferent_access
      #   klass = options.fetch("class_name", name).camelize.constantize
      #   attribute name, initializer: -> { RelationAttribute.new(klass) }

      #   define_method "create_#{name}" do |*args|
      #     # TODO: Can we do this in batches?
      #     record = klass.create(*args)
      #     update(name => record.ref)
      #   end
      # end

      def attribute(name, type: String)
        __attributes_definition[name] = -> { Attribute.new(type: type) }

        instance_eval do
          define_method(name) do
            read_attribute(name)
          end

          define_method("#{name}=") do |value|
            write_attribute(name, value)
          end
        end
      end
    end

    module InstanceMethods
      def initialize(new_attrs = {})
        @__attributes = {}.with_indifferent_access
        assign_attributes(new_attrs.with_indifferent_access)
      end

      def write_attribute(name, value)
        @__attributes[name].write(value)
      end

      def read_attribute(name)
        @__attributes.fetch(name).read
      end

      def assign_attributes(new_attrs)
        self.class.__attributes_definition.keys.each do |name|
          @__attributes[name] = self.class.__attributes_definition[name].call
          @__attributes[name].write(new_attrs[name])
        end
      end

      def attributes
        @__attributes.map.with_object({}) { |(key, value), memo| memo[key] = value.read }
      end

      def inspect
        inspection = attributes.map { |key, value| "#{key}: #{value.inspect}" }
        if attributes.empty?
          "#<#{self.class} id: #{@id.inspect }>"
        else
          "#<#{self.class} id: #{@id.inspect }, #{inspection.join(", ")}>"
        end
      end

      def to_s
        inspect
      end

      def id
        @id
      end

      def id=(id)
        @id = id
      end
    end
  end
end
