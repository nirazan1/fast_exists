# frozen_string_literal: true

require "spec_helper"

RSpec.describe FastExists::MultiTenant::Strategies::AdaptiveStrategy do
  subject(:strategy) { described_class.new }

  it "classifies tenants dynamically based on record count thresholds" do
    expect(strategy.classify_tenant("tenant_1", 5_000)).to eq(:tiny)
    expect(strategy.classify_tenant("tenant_2", 50_000)).to eq(:small)
    expect(strategy.classify_tenant("tenant_3", 500_000)).to eq(:medium)
    expect(strategy.classify_tenant("tenant_4", 1_500_000)).to eq(:large)
  end

  it "routes tiny tenants to shared tiny pool and large tenants to dedicated filter" do
    strategy.set_tenant_category("tenant_tiny", :tiny)
    strategy.set_tenant_category("tenant_large", :large)

    strategy.add("tenant_tiny", "email", "tiny@example.com")
    strategy.add("tenant_large", "email", "large@example.com")

    expect(strategy.contains?("tenant_tiny", "email", "tiny@example.com")).to be true
    expect(strategy.contains?("tenant_large", "email", "large@example.com")).to be true
    expect(strategy.contains?("tenant_tiny", "email", "missing@example.com")).to be false
  end
end

RSpec.describe FastExists::MultiTenant::RecommendationEngine do
  it "simulates 10,000 tenants and recommends adaptive strategy" do
    tenants = {}
    10_000.times do |i|
      tenants[i + 1] = i < 10 ? 1_200_000 : (i < 500 ? 50_000 : 2_000)
    end

    rec = described_class.analyze(tenants)

    expect(rec[:total_tenants]).to eq(10_000)
    expect(rec[:buckets][:tiny]).to eq(9500)
    expect(rec[:buckets][:large]).to eq(10)
    expect(rec[:recommended_strategy]).to eq(:adaptive)
    expect(rec[:estimated_redis_keys]).to eq(13) # 3 shared pools + 10 dedicated
    expect(rec[:redis_key_reduction_pct]).to be >= 99.0
  end
end
