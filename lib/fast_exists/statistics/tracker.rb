# frozen_string_literal: true

require "thread"

module FastExists
  module Statistics
    class Tracker
      attr_reader :queries_avoided, :database_lookups, :bloom_hits, :bloom_misses, :false_positives

      def initialize
        @mutex = Mutex.new
        reset!
      end

      def record_avoided
        @mutex.synchronize do
          @queries_avoided += 1
          @bloom_misses += 1
        end
      end

      def record_hit
        @mutex.synchronize do
          @bloom_hits += 1
        end
      end

      def record_db_lookup
        @mutex.synchronize do
          @database_lookups += 1
        end
      end

      def record_false_positive
        @mutex.synchronize do
          @false_positives += 1
        end
      end

      def hit_ratio
        total = @bloom_hits + @bloom_misses
        return 0.0 if total.zero?
        (@bloom_hits.to_f / total).round(4)
      end

      def miss_ratio
        total = @bloom_hits + @bloom_misses
        return 0.0 if total.zero?
        (@bloom_misses.to_f / total).round(4)
      end

      def false_positive_rate
        return 0.0 if @bloom_hits.zero?
        (@false_positives.to_f / @bloom_hits).round(4)
      end

      def snapshot
        @mutex.synchronize do
          {
            queries_avoided: @queries_avoided,
            database_lookups: @database_lookups,
            bloom_hits: @bloom_hits,
            bloom_misses: @bloom_misses,
            false_positives: @false_positives,
            hit_ratio: hit_ratio,
            miss_ratio: miss_ratio,
            false_positive_rate: false_positive_rate
          }
        end
      end

      def reset!
        @mutex.synchronize do
          @queries_avoided = 0
          @database_lookups = 0
          @bloom_hits = 0
          @bloom_misses = 0
          @false_positives = 0
        end
      end
    end
  end
end
