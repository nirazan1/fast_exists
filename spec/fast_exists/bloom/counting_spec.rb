# frozen_string_literal: true

require "spec_helper"

RSpec.describe FastExists::Bloom::Counting do
  subject(:counting) { described_class.new(expected_elements: 100, false_positive_rate: 0.01) }

  it "adds and removes elements" do
    counting.add("item1")
    expect(counting.contains?("item1")).to be true

    counting.delete("item1")
    expect(counting.contains?("item1")).to be false
  end
end
