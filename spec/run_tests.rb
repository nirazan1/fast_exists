# frozen_string_literal: true

require "minitest/autorun"
require_relative "../lib/fast_exists"

begin
  require "active_record"
  ActiveRecord::Base.establish_connection(
    adapter: "sqlite3",
    database: ":memory:"
  )

  ActiveRecord::Schema.define do
    create_table :users, force: true do |t|
      t.string :email
      t.string :username
      t.timestamps
    end
    add_index :users, :email, unique: true
  end

  class User < ActiveRecord::Base
    include FastExists::ActiveRecord::Extension
    fast_exists :email
    fast_exists :username
    validates :email, uniqueness: true
  end
  ACTIVE_RECORD_AVAILABLE = true
rescue LoadError
  ACTIVE_RECORD_AVAILABLE = false
end

class FastExistsTest < Minitest::Test
  def setup
    FastExists.reset_stats!
    User.delete_all if defined?(User)
  end

  def test_bit_array
    ba = FastExists::BitArray.new(100)
    assert_equal 100, ba.size
    assert_equal false, ba.get(10)
    ba.set(10)
    assert_equal true, ba.get(10)
    assert_equal 1, ba.count_ones
    ba.clear
    assert_equal 0, ba.count_ones
  end

  def test_bloom_filter
    bf = FastExists::Bloom::Filter.new(expected_elements: 1000, false_positive_rate: 0.01)
    bf.add("alice@example.com")
    assert_equal true, bf.contains?("alice@example.com")
    assert_equal false, bf.contains?("bob@example.com")
  end

  def test_performance_intelligence_stats
    json_stats = FastExists.stats(format: :json)
    assert_includes json_stats, "queries_avoided"

    md_stats = FastExists.stats(format: :markdown)
    assert_includes md_stats, "FastExists Runtime Statistics"
  end

  def test_performance_intelligence_health
    health = FastExists.health!
    assert_equal :healthy, health[:overall_status]
    assert health[:checks].any? { |c| c[:name] == "Backend Availability" }
  end

  def test_performance_intelligence_analyze
    skip "ActiveRecord gem not loaded" unless ACTIVE_RECORD_AVAILABLE
    analysis = FastExists.analyze!
    assert analysis.has_key?(:models)
  end

  def test_performance_intelligence_audit
    skip "ActiveRecord gem not loaded" unless ACTIVE_RECORD_AVAILABLE
    audit = FastExists.audit!
    assert audit.has_key?(:audit_score)
    assert audit.has_key?(:grade)
  end

  def test_performance_intelligence_doctor
    doctor = FastExists.doctor!(format: :markdown)
    assert_includes doctor, "FastExists Doctor Diagnostic Report"
  end

  def test_performance_intelligence_report
    html_report = FastExists.report!(format: :html)
    assert_includes html_report, "FastExists Performance Intelligence Report"

    csv_report = FastExists.report!(format: :csv)
    assert_includes csv_report, "Overall Status"
  end

  def test_cli_suite_commands
    out, _ = capture_io { FastExists::CLI.start(["version"]) }
    assert_match(/fast_exists v/, out)

    health_out, _ = capture_io { FastExists::CLI.start(["health"]) }
    assert_match(/Operational Health Status/, health_out)
  end

  def test_multi_tenant_adaptive_strategy
    adaptive = FastExists::MultiTenant::Strategies::AdaptiveStrategy.new
    assert_equal :tiny, adaptive.classify_tenant(1, 100)
    assert_equal :small, adaptive.classify_tenant(2, 50_000)
    assert_equal :medium, adaptive.classify_tenant(3, 500_000)
    assert_equal :large, adaptive.classify_tenant(4, 2_000_000)

    adaptive.add(1, "email", "test@example.com")
    assert_equal true, adaptive.contains?(1, "email", "test@example.com")
    assert_equal false, adaptive.contains?(1, "email", "missing@example.com")
  end

  def test_multi_tenant_recommendation_engine
    tenants = {}
    4287.times { |i| tenants[i + 1] = i < 10 ? 1_200_000 : 2_000 }
    rec = FastExists::MultiTenant::RecommendationEngine.analyze(tenants)
    assert_equal 4287, rec[:total_tenants]
    assert_equal 13, rec[:estimated_redis_keys]
    assert rec[:redis_key_reduction_pct] >= 99.0
  end
end
