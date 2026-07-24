# frozen_string_literal: true

require "json"
require "yaml"

module FastExists
  module Intelligence
    class Stats
      def self.render(format: :console)
        raw_stats = FastExists.stats.merge(
          active_backend: FastExists.configuration.backend,
          uptime_seconds: (FastExists.uptime rescue 0),
          sync_status: FastExists.configuration.auto_sync ? :active : :disabled
        )

        case format.to_sym
        when :json
          JSON.pretty_generate(raw_stats)
        when :yaml
          raw_stats.transform_keys(&:to_s).to_yaml
        when :markdown
          to_markdown(raw_stats)
        else
          to_console(raw_stats)
        end
      end

      private

      def self.to_console(s)
        <<~CONSOLE
          ==================================================
          ⚡ FastExists Runtime Statistics
          ==================================================
          Active Backend:            #{s[:active_backend]}
          Memory Usage:             #{s[:memory_usage] || 'N/A'}
          Capacity:                 #{s[:capacity] || 'N/A'}
          Occupancy:                #{s[:occupancy] || 'N/A'}
          Bit Array Size:           #{s[:bit_size] || 'N/A'}
          Hash Count:               #{s[:hash_count] || 'N/A'}
          Inserted Elements:        #{s[:inserted_items] || 0}
          Expected Elements:        #{s[:expected_elements] || 0}
          Est. False Positive Rate: #{s[:estimated_false_positive_rate] || 0.0}%
          Actual False Positives:   #{s[:false_positives]}
          Bloom Hits:               #{s[:bloom_hits]}
          Bloom Misses:             #{s[:bloom_misses]}
          Queries Avoided:          #{s[:queries_avoided]}
          Database Lookups:         #{s[:database_lookups]}
          Hit Ratio:                #{(s[:hit_ratio] * 100).round(2)}%
          Miss Ratio:               #{(s[:miss_ratio] * 100).round(2)}%
          Synchronization Status:   #{s[:sync_status]}
          ==================================================
        CONSOLE
      end

      def self.to_markdown(s)
        <<~MARKDOWN
          # ⚡ FastExists Runtime Statistics

          | Metric | Value |
          |:---|:---|
          | **Active Backend** | `#{s[:active_backend]}` |
          | **Capacity** | #{s[:capacity] || 'N/A'} |
          | **Inserted Elements** | #{s[:inserted_items] || 0} |
          | **Queries Avoided** | **#{s[:queries_avoided]}** |
          | **Database Lookups** | #{s[:database_lookups]} |
          | **Bloom Hits** | #{s[:bloom_hits]} |
          | **Bloom Misses** | #{s[:bloom_misses]} |
          | **False Positives** | #{s[:false_positives]} |
          | **Hit Ratio** | #{(s[:hit_ratio] * 100).round(2)}% |
          | **Miss Ratio** | #{(s[:miss_ratio] * 100).round(2)}% |
          | **Est. FP Rate** | #{s[:estimated_false_positive_rate] || 0.0}% |
          | **Sync Status** | `#{s[:sync_status]}` |
        MARKDOWN
      end
    end
  end
end
