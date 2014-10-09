require 'spec_helper'

describe Datastreams::Bibframe::WorkMetadata do
  before :all do
    file = File.new('./spec/fixtures/test_book.xml')
    @ds = Datastreams::Bibframe::WorkMetadata.from_xml(file)
  end
  it 'parses a title' do
    expect(@ds.title).to eql ['The adventures of Oliver Twist']
  end

  it 'has a uniform_title method' do
    expect(@ds.uniform_title).to eql ['Oliver Twist.']
  end

  it 'parses a topic label' do
    expect(@ds.subject.Topic.label).to eql ['Orphans--Fiction']
  end
end
