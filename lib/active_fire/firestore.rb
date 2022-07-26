require 'google/cloud/firestore'

module ActiveFire
  module Firestore
    class Client
      attr_reader :service

      def initialize
        @service = ::Google::Cloud::Firestore.new(
          credentials: ENV.fetch('CREDENTIALS_FILE')
        )
      end

      def doc(ref)
        @service.doc(ref)
      end

      def find(doc)
        doc.get
      end

      def where(doc, *options)
        doc.where(*options)
      end

      def update(doc, attributes)
        doc.set(attributes, merge: true)
      end

      def delete(doc)
        @doc.delete
      end

      def document(collection)
        collection.document
      end

      def collection(collection)
        @service.collection(collection)
      end
    end
  end
end