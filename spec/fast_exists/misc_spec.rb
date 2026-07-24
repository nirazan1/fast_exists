# frozen_string_literal: true

require "spec_helper"

RSpec.describe FastExists::MultiTenancy::Resolver do
  it "resolves lambda, symbol, string namespaces" do
    expect(described_class.resolve("tenant_1")).to eq("tenant_1")
    expect(described_class.resolve(->(_ctx) { "tenant_42" })).to eq("tenant_42")
  end
end

RSpec.describe FastExists::Statistics::Tracker do
  subject(:tracker) { described_class.new }

  it "records avoided queries and hits" do
    tracker.record_avoided
    tracker.record_hit
    tracker.record_db_lookup

    snap = tracker.snapshot
    expect(snap[:queries_avoided]).to eq(1)
    expect(snap[:bloom_hits]).to eq(1)
    expect(snap[:database_lookups]).to eq(1)
  end
end

RSpec.describe FastExists::Instrumentation::Prometheus do
  it "exports prometheus formatted metrics" do
    metrics = described_class.to_metrics
    expect(metrics).to include("fast_exists_queries_avoided")
    expect(metrics).to include("fast_exists_database_lookups")
  end
end

RSpec.describe FastExists::Optimizer::AiAdvisor do
  it "provides optimization suggestions" do
    analysis = described_class.analyze(User)
    expect(analysis).to have_key(:recommendations)
    expect(analysis[:recommendations]).to have_key(:recommended_backend)
  end
end

RSpec.describe FastExists::CLI do
  it "executes version command without error" do
    expect { described_class.start(["version"]) }.to output(/fast_exists v/).to_stdout
  end
end
