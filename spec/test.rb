

require 'bundler/setup'
require 'dotenv/load'
require 'active_fire'
require 'pry'

a = ActiveFire::Client.new
col = a.firestore.col('todos').doc('clGZ65kXfMhql68VKsI0')

class Todo < ActiveFire::Base
  attribute :title
end

todo = Todo.new(col.get)
binding.pry
puts todo