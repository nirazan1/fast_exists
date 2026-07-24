# frozen_string_literal: true

require "spec_helper"

RSpec.describe FastExists::BitArray do
  subject(:bit_array) { described_class.new(100) }

  it "initializes with specified size" do
    expect(bit_array.size).to eq(100)
    expect(bit_array.bytesize).to eq(13)
  end

  it "sets and gets bit values" do
    expect(bit_array.get(42)).to be false
    bit_array.set(42)
    expect(bit_array.get(42)).to be true
  end

  it "raises IndexError on out of bounds" do
    expect { bit_array.get(200) }.to raise_error(IndexError)
    expect { bit_array.set(-1) }.to raise_error(IndexError)
  end

  it "clears all set bits" do
    bit_array.set(10)
    bit_array.set(20)
    expect(bit_array.count_ones).to eq(2)
    bit_array.clear
    expect(bit_array.count_ones).to eq(0)
    expect(bit_array.get(10)).to be false
  end

  it "supports byte dump and load" do
    bit_array.set(5)
    bit_array.set(95)
    bytes = bit_array.to_s
    loaded = described_class.from_s(bytes, 100)
    expect(loaded.get(5)).to be true
    expect(loaded.get(95)).to be true
    expect(loaded.get(50)).to be false
  end

  it "is thread safe" do
    threads = Array.new(10) do |i|
      Thread.new do
        10.times { |j| bit_array.set(i * 10 + j) }
      end
    end
    threads.each(&:join)
    expect(bit_array.count_ones).to eq(100)
  end
end
