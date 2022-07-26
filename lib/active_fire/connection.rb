require 'singleton'

module ActiveFire
  class Connection
    def self.client
      instance.client
    end

    def self.client=(client)
      instance.client = client
    end

    include Singleton

    def initialize
      # @client = ActiveFire::Firestore::Client.new
    end

    def client=(client)
      @client = client
    end

    def client
      @client
    end
  end
end
