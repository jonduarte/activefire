class DummyAuthor < ActiveFire::Base
  attribute :name
  attribute :age, type: Integer
end

class DummyDoc
  def initialize(data)
    collection, id = data.split("/")
    @data = { data: { "id": id } }
  end

  def data
    @data
  end
end

class DummyCol
  attr_reader :conditions

  def initialize(name)
    @name = name
    @conditions = []
  end

  def where(*options)
    @conditions.push([@name, options])
    self
  end

  def limit(*options)
    @conditions.push([@name, 'limit', options])
    self
  end
end

class DummyClient
  attr_reader :cols

  def initialize
    @cols = []
    @docs = {}
  end

  def doc(ref)
    @docs[ref] = DummyDoc.new(ref)
    ref
  end

  def find(ref)
    @docs[ref]
  end

  def collection(collection_name)
    col = DummyCol.new(collection_name)
    @cols.push(col)
    col
  end
end

RSpec.describe ActiveFire do
  it 'has a version number' do
    expect(ActiveFire::VERSION).not_to be nil
  end

  describe 'model initialization' do
    let(:author) { DummyAuthor.new }

    context 'with empty parameters' do
      let(:author) { DummyAuthor.new }

      it 'initializes fields with nil' do
        expect(author.name).to be_nil
        expect(author.age).to be_nil
      end
      
      it 'only has defined attributes' do
        expect { author.non_existent }.to raise_error(NoMethodError)
      end
    end

    context 'with initialized values' do
      let(:author) { DummyAuthor.new(name: 'Jose', age: 20) }

      it 'initializes fields with value' do
        expect(author.name).to eq('Jose')
        expect(author.age).to eq(20)
      end

      context 'casting' do
        let(:author) { DummyAuthor.new(age: "20") }

        it 'converts attribute to correct type' do
          expect(author.age).to eq(20)
        end
      end

      describe '#to_s' do
        subject { author.to_s }
        it { is_expected.to eq(%q{#<DummyAuthor id: nil, name: "Jose", age: 20>}) }
      end
    end
  end
end

RSpec.describe ActiveFire::Persistence do
  describe '.collection_name' do
    let(:author) { DummyAuthor.new }

    it 'has a default value' do
      expect(DummyAuthor.collection_name).to eq('dummy_authors')
      expect(author.collection_name).to eq('dummy_authors')
    end

    it 'can be changed' do
      class DummyAuthor
        self.collection_name = 'dummies'
      end

      expect(DummyAuthor.collection_name).to eq('dummies')
      expect(DummyAuthor.new.collection_name).to eq('dummies')
    end
  end

  describe ActiveFire::Persistence::Utils do
    let(:client) { DummyClient.new }
    before { ActiveFire::Connection.client = client }

    describe '.build_doc' do
      it 'creates document reference value' do
        expect(described_class.build_doc('players')).to eq('players')
        expect(described_class.build_doc('players', '123')).to eq('players/123')
      end
    end
  end


  describe 'conditions' do
    let(:client) { DummyClient.new }
    before { ActiveFire::Connection.client = client }

    it 'build queries' do
      DummyAuthor.where(name: 'Jose')
      expect(client.cols.map(&:conditions)).to eq([[['dummies', [:name, :eq, 'Jose']]]])
    end

    it 'build chained queries' do
      DummyAuthor.where(name: 'Jose').where(:age, '>', 10).limit(10)
      expect(client.cols.map(&:conditions)).to eq([[
        ['dummies', [:name, :eq, 'Jose']],
        ['dummies', [:age, '>', 10]],
        ['dummies', 'limit', [10]]
      ]])
    end

    it 'find specific record' do
      expect(DummyAuthor.find('abc').id).to eq('abc')
    end
  end
end
