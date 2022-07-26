require 'google/cloud/firestore'

module ActiveFire
class Client
    attr_reader :firestore

    def initialize
      @firestore = Google::Cloud::Firestore.new(
        project_id: ENV.fetch('PROJECT_NAME'),
        credentials: ENV.fetch('CREDENTIALS_FILE')
      )
    end
  end

  class Base
    extend ActiveFire::Attributes
    extend ActiveFire::Persistence
  end
end

# a = ActiveFire::Client.new
# col = a.firestore.col('players').doc('oPBVulSlZEAXNJrjEOJX')
# 
# class Player < ActiveFire::Base
#   field :name, type: Integer
# end
# 
# PLAYER = Player.new(col.get)
