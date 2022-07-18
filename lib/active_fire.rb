require 'active_fire/version'
require 'google/cloud/firestore'

module ActiveFire
  class Error < StandardError; end

  class Client
    attr_reader :firestore

    def initialize
      @firestore = Google::Cloud::Firestore.new(
        project_id: ENV.fetch('PROJECT_NAME'),
        credentials: ENV.fetch('CREDENTIALS_FILE')
      )
    end
  end

  module ActiveFire::Naming
    def table_name
      name
    end

    def __private_types
      @__private_types ||= {}
    end

    def field(name, type:)
      if type == nil
        type = String
      end
      __private_types[name] = type

      define_method name do
        data[name]
      end

      define_method("#{name}=") do |value|
        casted = value
        cast = self.class.__private_types[name]
        if !value.is_a?(cast)
          puts "casted to: #{cast}"
          cast = eval("#{cast}(\"#{value}\")")
        end

        puts "Value: #{value}"
      end
    end
  end

  class Base
    extend ActiveFire::Naming

    def initialize(ref)
      @ref = ref
    end

    def data
      @ref.data
    end
  end
end

a = ActiveFire::Client.new
col = a.firestore.col('players').doc('oPBVulSlZEAXNJrjEOJX')

class Player < ActiveFire::Base
  field :name, type: Integer
end

PLAYER = Player.new(col.get)
