# frozen_string_literal: true

require "spec_helper"

RSpec.describe FastExists::Probabilistic::Cuckoo do
  subject(:cuckoo) { described_class.new(capacity: 100) }

  it "supports insert, lookup, and deletion" do
    cuckoo.add("session_123")
    expect(cuckoo.contains?("session_123")).to be true

    cuckoo.delete("session_123")
    expect(cuckoo.contains?("session_123")).to be false
  end
end

RSpec.describe FastExists::Probabilistic::HyperLogLog do
  subject(:hll) { described_class.new(p: 10) }

  it "estimates cardinality accurately" do
    100.times { |i| hll.add("user_#{i}") }
    expect(hll.count).to be_within(20).of(100)
  end
end

RSpec.describe FastExists::Probabilistic::CountMinSketch do
  subject(:cms) { described_class.new(epsilon: 0.01, confidence: 0.99) }

  it "estimates item frequency accurately" do
    5.times { cms.add("event_click") }
    expect(cms.estimate("event_click")).to be >= 5
    expect(cms.estimate("event_view")).to eq(0)
  end
end
