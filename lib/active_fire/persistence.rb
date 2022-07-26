require "active_support/core_ext/string/inflections"

module ActiveFire
  class Query
    include Enumerable

    def initialize(klass)
      @klass = klass
      @col = Connection.client.collection(@klass.collection_name)
    end

    def where!(*args)
      if comparing_equality?(args)
        args[0].each { |(name, value)| build_query!(name, :eq, value) }
      else
        build_query!(*args)
      end

      self
    end

    def limit!(*args)
      if @query
        @query = @query.limit(*args)
      else
        @query = @col.limit(*args)
      end

      self
    end

    def offset!(*args)
      if @query
        @query = @query.offset(*args)
      else
        @query = @col.offset(*args)
      end

      self
    end

    def all!
      if !@query
        @query = @col
      end

      self
    end

    def all
      dup.all!
    end

    def offset(*args)
      dup.offset!(*args)
    end

    def limit(*args)
      dup.limit!(*args)
    end

    def where(*args)
      dup.where!(*args)
    end

    def each(&block)
      @query.get.lazy.each do |doc|
        model = @klass.setup(doc.document_id, @doc.data)
        yield model
      end
    end

    def last
      to_a.last
    end

    private
      def comparing_equality?(args)
        args.size == 1 && args[0].kind_of?(Hash)
      end

      def build_query!(*args)
        if @query
          @query = @query.where(*args)
        else
          @query = @col.where(*args)
        end
      end
  end

  module Model
    def setup(id, attrs)
      record = new(attrs)
      record.id = id

      yield record if block_given?

      record
    end
  end

  module Persistence
    class Utils
      class << self
        def build_doc(col, id = nil)
          ref = [col, id].reject(&blank?).join("/")
          ActiveFire::Connection.client.doc(ref)
        end
      end
    end

    def self.extended(base)
      base.extend(ClassMethods)
      base.include(InstanceMethods)

      base.extend(ActiveFire::Model)
    end

    module InstanceMethods
      def update(attrs = {})
        assign_attributes(attrs)
        !!Connection.client.update(ref, attributes).update_time
      end

      def collection_name
        self.class.collection_name
      end

      def ref
        Util.build_doc(self.class.collection_name, id)
      end

      def delete
        !!Connection.client.delete(ref).update_time
      end

      def reload!
        if reloaded = self.class.find(id)
          assign_attributes(reloaded.attributes)
        end

        self
      end
    end

    module ClassMethods
      def collection_name
        @collection_name ||= self.name.to_s.pluralize.underscore
      end

      def collection_name=(value)
        @collection_name = value
      end

      def create(attributes)
        collection = Connection.client.collection(collection_name)
        id = Connection.client.document(collection).document_id
        setup(id, attributes) { |record| record.update }
      end

      def find(id)
        doc = Utils.build_doc(collection_name, id)
        attrs = Connection.client.find(doc).data
        setup(id, attrs)
      end

      def find_by(*options)
        where(*options).first
      end

      def where(*args)
        ActiveFire::Query.new(self).where(*args)
      end

      def all
        ActiveFire::Query.new(self).all
      end

      def limit(*args)
        ActiveFire::Query.new(self).limit(*args)
      end

      def offset(*args)
        ActiveFire::Query.new(self).offset(*args)
      end
    end
  end
end
