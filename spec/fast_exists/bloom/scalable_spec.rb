# frozen_string_literal: true

require "spec_helper"

RSpec.describe FastExists::Bloom::Scalable do
  subject(:scalable) { described_class.new(initial_capacity: 10, false_positive_rate: 0.01) }

  it "expands dynamically beyond initial capacity" do
    25.times { |i| scalable.add("item_#{i}") }

    expect(scalable.count).to eq(25)
    expect(scalable.capacity).to be > 10
    expect(scalable.contains?("item_5")).to be true
    expect(scalable.contains?("nonexistent")).to be false
  end

  it "clears filters successfully" do
    scalable.add("sample")
    scalable.clear
    expect(scalable.count).to eq(0)
    expect(scalable.contains?("sample")).to be false
  end
end
