require 'active_support/core_ext/hash/indifferent_access'

module ActiveFire
  module Attributes
    class Attribute
      attr_accessor :value
      attr_accessor :record
    end

    class BelongsToAttribute < Attribute
      attr_accessor :value
      attr_reader :related_to

      def initialize(related_to:)
        @related_to = related_to
      end

      def value=(v)
        
        if v.is_a?(Google::Cloud::Firestore::DocumentReference)
          record.send("#{related_to}=", related_to_klass.load(v.get))
          @value = v.document_id
        else
          doc = build_doc(v)
          record.send("#{related_to}=", related_to_klass.find(doc.document_id))
          @value = doc
        end
      end

      private
        def related_to_klass
          related_to.to_s.camelize.constantize
        end

        def build_doc(v)
          if v.start_with?("/")
            v = v[1..-1]
          end
          col, id = v.split("/")
          Persistence.build_doc(col, id)
        end
    end

    def self.extended(base)
      base.extend ClassMethods
      base.include InstanceMethods
    end

    module ClassMethods
      def __attributes_definition
        @__attributes_definition ||= {}.with_indifferent_access
      end

      def belongs_to(name)
        __attributes_definition["#{name}_id"] = -> { BelongsToAttribute.new(related_to: name) }
        attribute name
      end

      def attribute(name, initializer: -> { Attribute.new })
        __attributes_definition[name] = initializer

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
        assign_attributes({ name => value })
      end

      def read_attribute(name)
        @__attributes[name]&.value
      end

      def assign_attributes(new_attrs)
        new_attrs.each do |key, value|
          next unless self.class.__attributes_definition[key].present?
          attribute = self.class.__attributes_definition[key].call
          attribute.record = self
          @__attributes[key] = attribute
          @__attributes[key].value = value
        end
      end

      def attributes
        reject = {}.with_indifferent_access 
        @__attributes.map.with_object({}.with_indifferent_access) do |(key, value), memo|
          if value.is_a?(BelongsToAttribute)
            reject[value.related_to] = true
          end

          next if reject[key]
          memo[key] = value.value
        end
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
