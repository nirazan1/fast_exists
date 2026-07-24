# frozen_string_literal: true

require "benchmark"
require_relative "../lib/fast_exists"

module FastExists
  class BenchmarkSuite
    def self.run!
      puts "=========================================================="
      puts "  FAST_EXISTS BENCHMARK SUITE"
      puts "  Ruby Version: #{RUBY_VERSION}"
      puts "=========================================================="
      puts

      filter = FastExists::Bloom::Filter.new(expected_elements: 1_000_000, false_positive_rate: 0.001)

      puts "--> Seeding Bloom Filter with 100,000 items..."
      100_000.times { |i| filter.add("user_#{i}@example.com") }

      puts "--> Running 100,000 Negative Lookups (Key NOT in filter)..."
      time_neg = Benchmark.realtime do
        100_000.times do |i|
          filter.contains?("nonexistent_#{i}@example.com")
        end
      end
      ops_neg = (100_000 / time_neg).round
      puts "    Completed in #{time_neg.round(4)}s (#{ops_neg} ops/sec)"

      puts "--> Running 100,000 Positive Lookups (Key IS in filter)..."
      time_pos = Benchmark.realtime do
        100_000.times do |i|
          filter.contains?("user_#{i}@example.com")
        end
      end
      ops_pos = (100_000 / time_pos).round
      puts "    Completed in #{time_pos.round(4)}s (#{ops_pos} ops/sec)"

      puts "--> Running 100,000 Mixed Lookups (50% positive / 50% negative)..."
      time_mix = Benchmark.realtime do
        100_000.times do |i|
          key = i.even? ? "user_#{i}@example.com" : "missing_#{i}@example.com"
          filter.contains?(key)
        end
      end
      ops_mix = (100_000 / time_mix).round
      puts "    Completed in #{time_mix.round(4)}s (#{ops_mix} ops/sec)"

      puts
      puts "=========================================================="
      puts "  Benchmark Complete!"
      puts "=========================================================="
    end
  end
end

if __FILE__ == $0
  FastExists::BenchmarkSuite.run!
end
