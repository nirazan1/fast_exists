# frozen_string_literal: true

require "spec_helper"

RSpec.describe FastExists::Bloom::Filter do
  subject(:filter) { described_class.new(expected_elements: 1000, false_positive_rate: 0.01) }

  it "calculates optimal bit size and hash count" do
    expect(filter.bit_size).to be > 1000
    expect(filter.hash_count).to be >= 1
  end

  it "adds items and reports positive existence" do
    filter.add("alice@example.com")
    expect(filter.contains?("alice@example.com")).to be true
  end

  it "returns false for non-inserted items (no false negatives)" do
    filter.add("alice@example.com")
    expect(filter.contains?("bob@example.com")).to be false
  end

  it "clears all inserted items" do
    filter.add("test")
    filter.clear
    expect(filter.count).to eq(0)
    expect(filter.contains?("test")).to be false
  end

  it "exports and imports serialized dump state" do
    filter.add("hello")
    filter.add("world")

    dumped = filter.dump
    restored = described_class.load(dumped)

    expect(restored.contains?("hello")).to be true
    expect(restored.contains?("world")).to be true
    expect(restored.contains?("foo")).to be false
  end

  it "returns accurate statistics" do
    filter.add("one")
    stats = filter.stats
    expect(stats[:inserted_items]).to eq(1)
    expect(stats[:expected_elements]).to eq(1000)
    expect(stats[:false_positive_rate]).to eq(0.01)
  end
end
