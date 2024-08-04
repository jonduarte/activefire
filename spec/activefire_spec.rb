# Project name:string
class Project < ActiveFire::Base
  attribute :name

  has_many :todos
end

# Todo title:string completed:boolean project_id:references
class Todo < ActiveFire::Base
  attribute :title
  attribute :completed

  belongs_to :project
end

RSpec.describe ActiveFire::Base do
  describe '#create' do
    it 'stores document' do
      todo = Todo.create(title: 'Buy bread', completed: false)
      expect(todo.id).to_not be_nil
      expect(todo.title).to eq('Buy bread')
      expect(todo.completed).to be(false)
    end
  end

  describe '#update' do
    it 'changes attribute in the database' do
      todo = Todo.create(title: 'Buy bread', completed: false)
      id = todo.id
      todo.update(title: 'Brot kaufen')
      todo = Todo.find(id)
      expect(todo.title).to eq('Brot kaufen')
    end
  end


  describe '.find' do
    it 'returns existing record' do
      todo = Todo.find('clGZ65kXfMhql68VKsI0')
      expect(todo.collection_name).to eq('todos')
      expect(todo.title).to eq('Buy milk')
      expect(todo.completed).to be
    end
  end

  describe '.where' do
    it 'returns objects based on a query' do
      todos = Todo.where(completed: true)
      expect(todos.size).to eq(1)

      todo = todos.first
      expect(todo.title).to eq('Buy milk')
    end
  end

  context 'associations' do
    it 'loads belongs to association' do
      todo = Todo.find('clGZ65kXfMhql68VKsI0')
      expect(todo.project.name).to eq('Birthday')
      expect(todo.project.id).to eq('C23Cuhlb0VMOCdW5xNwB')
    end

    it 'saves association' do
      c = Todo.create(title: "Link project", project_id: "/projects/C23Cuhlb0VMOCdW5xNwB")
      expect(c.project.name).to eq('Birthday')
    end

    it 'has many' do
      c = Todo.create(title: "Link project", project_id: "/projects/C23Cuhlb0VMOCdW5xNwB")
      p = Project.find("C23Cuhlb0VMOCdW5xNwB")
      c1 = p.todos.find { |t| t.id == c.id }
      expect(c1.id).to eq(c.id)
    end
  end
end

# RSpec.describe ActiveFire do
#   it 'has a version number' do
#     expect(ActiveFire::VERSION).not_to be nil
#   end

#   describe 'model initialization' do
#     let(:author) { DummyAuthor.new }

#     context 'with empty parameters' do
#       let(:author) { DummyAuthor.new }

#       it 'initializes fields with nil' do
#         expect(author.name).to be_nil
#         expect(author.age).to be_nil
#       end
      
#       it 'only has defined attributes' do
#         expect { author.non_existent }.to raise_error(NoMethodError)
#       end
#     end

#     context 'with initialized values' do
#       let(:author) { DummyAuthor.new(name: 'Jose', age: 20) }

#       it 'initializes fields with value' do
#         expect(author.name).to eq('Jose')
#         expect(author.age).to eq(20)
#       end

#       context 'casting' do
#         let(:author) { DummyAuthor.new(age: "20") }

#         it 'converts attribute to correct type' do
#           expect(author.age).to eq(20)
#         end
#       end

#       describe '#to_s' do
#         subject { author.to_s }
#         it { is_expected.to eq(%q{#<DummyAuthor id: nil, name: "Jose", age: 20>}) }
#       end
#     end
#   end
# end

# RSpec.describe ActiveFire::Persistence do
#   describe '.collection_name' do
#     let(:author) { DummyAuthor.new }

#     it 'has a default value' do
#       expect(DummyAuthor.collection_name).to eq('dummy_authors')
#       expect(author.collection_name).to eq('dummy_authors')
#     end

#     it 'can be changed' do
#       class DummyAuthor
#         self.collection_name = 'dummies'
#       end

#       expect(DummyAuthor.collection_name).to eq('dummies')
#       expect(DummyAuthor.new.collection_name).to eq('dummies')
#     end
#   end

#   describe ActiveFire::Persistence::Utils do
#     let(:client) { DummyClient.new }
#     before { ActiveFire::Connection.client = client }

#     describe '.build_doc' do
#       it 'creates document reference value' do
#         expect(described_class.build_doc('players')).to eq('players')
#         expect(described_class.build_doc('players', '123')).to eq('players/123')
#       end
#     end
#   end


#   describe 'conditions' do
#     let(:client) { DummyClient.new }
#     before { ActiveFire::Connection.client = client }

#     it 'build queries' do
#       DummyAuthor.where(name: 'Jose')
#       expect(client.cols.map(&:conditions)).to eq([[['dummies', [:name, :eq, 'Jose']]]])
#     end

#     it 'build chained queries' do
#       DummyAuthor.where(name: 'Jose').where(:age, '>', 10).limit(10)
#       expect(client.cols.map(&:conditions)).to eq([[
#         ['dummies', [:name, :eq, 'Jose']],
#         ['dummies', [:age, '>', 10]],
#         ['dummies', 'limit', [10]]
#       ]])
#     end

#     it 'find specific record' do
#       expect(DummyAuthor.find('abc').id).to eq('abc')
#     end
#   end
# end
