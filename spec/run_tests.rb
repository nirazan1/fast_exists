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
  end

  class User < ActiveRecord::Base
    include FastExists::ActiveRecord::Extension
    fast_exists :email
    fast_exists :username
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

  def test_scalable_bloom
    sb = FastExists::Bloom::Scalable.new(initial_capacity: 10)
    20.times { |i| sb.add("item_#{i}") }
    assert_equal 20, sb.count
    assert_equal true, sb.contains?("item_5")
    assert_equal false, sb.contains?("nonexistent")
  end

  def test_counting_bloom
    cb = FastExists::Bloom::Counting.new(expected_elements: 100)
    cb.add("item1")
    assert_equal true, cb.contains?("item1")
    cb.delete("item1")
    assert_equal false, cb.contains?("item1")
  end

  def test_cuckoo_filter
    cf = FastExists::Probabilistic::Cuckoo.new(capacity: 100)
    cf.add("key1")
    assert_equal true, cf.contains?("key1")
    cf.delete("key1")
    assert_equal false, cf.contains?("key1")
  end

  def test_hyperloglog
    hll = FastExists::Probabilistic::HyperLogLog.new(p: 10)
    100.times { |i| hll.add("val_#{i}") }
    assert_in_delta 100, hll.count, 25
  end

  def test_count_min_sketch
    cms = FastExists::Probabilistic::CountMinSketch.new(epsilon: 0.01, confidence: 0.99)
    5.times { cms.add("event_click") }
    assert cms.estimate("event_click") >= 5
    assert_equal 0, cms.estimate("event_view")
  end

  def test_active_record_integration
    skip "ActiveRecord gem not loaded" unless ACTIVE_RECORD_AVAILABLE

    # Negative lookup (avoided DB query)
    assert_equal false, User.email_exists?("missing@example.com")
    assert_equal 1, FastExists.stats[:queries_avoided]
    assert_equal 0, FastExists.stats[:database_lookups]

    # Create user record
    User.create!(email: "john@example.com", username: "john")

    assert_equal true, User.email_exists?("john@example.com")
    assert_equal true, User.username_exists?("john")
    assert_equal false, User.email_available?("john@example.com")
    assert_equal true, User.email_available?("new@example.com")
  end

  def test_backends
    mem = FastExists::Backends::Memory.new
    mem.add("k")
    assert_equal true, mem.contains?("k")

    null_b = FastExists::Backends::Null.new
    assert_equal true, null_b.contains?("anything")
  end

  def test_cli
    out, _ = capture_io { FastExists::CLI.start(["version"]) }
    assert_match(/fast_exists v/, out)
  end
end
