# frozen_string_literal: true

require "spec_helper"

RSpec.describe FastExists::Backends::Memory do
  subject(:backend) { described_class.new(expected_elements: 100) }

  it "adds and checks presence" do
    backend.add("item")
    expect(backend.contains?("item")).to be true
    expect(backend.contains?("missing")).to be false
  end
end

RSpec.describe FastExists::Backends::File do
  let(:tmp_file) { "tmp/spec_test_#{Time.now.to_i}.bloom" }
  subject(:backend) { described_class.new(file_path: tmp_file, expected_elements: 100) }

  after { File.delete(tmp_file) if File.exist?(tmp_file) }

  it "persists bit filter data to file" do
    backend.add("persistent_item")
    expect(File.exist?(tmp_file)).to be true

    reloaded = described_class.new(file_path: tmp_file, expected_elements: 100)
    expect(reloaded.contains?("persistent_item")).to be true
  end
end

RSpec.describe FastExists::Backends::Null do
  subject(:backend) { described_class.new }

  it "always returns true for contains? as safe fallback" do
    expect(backend.contains?("anything")).to be true
  end
end

RSpec.describe FastExists::Backends::Registry do
  subject(:registry) { described_class.new }

  it "fetches registered backends" do
    expect(registry.fetch(:memory)).to be_a(FastExists::Backends::Memory)
    expect(registry.fetch(:null)).to be_a(FastExists::Backends::Null)
  end

  it "raises UnsupportedBackendError for unregistered backends" do
    expect { registry.fetch(:unknown) }.to raise_error(FastExists::UnsupportedBackendError)
  end
end
