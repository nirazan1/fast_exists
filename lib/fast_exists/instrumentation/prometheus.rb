# frozen_string_literal: true

module FastExists
  module Instrumentation
    class Prometheus
      def self.to_metrics(stats = FastExists.stats)
        lines = []
        lines << "# HELP fast_exists_queries_avoided Total database queries avoided by Bloom filter"
        lines << "# TYPE fast_exists_queries_avoided counter"
        lines << "fast_exists_queries_avoided #{stats[:queries_avoided]}"

        lines << "# HELP fast_exists_database_lookups Total database lookups executed"
        lines << "# TYPE fast_exists_database_lookups counter"
        lines << "fast_exists_database_lookups #{stats[:database_lookups]}"

        lines << "# HELP fast_exists_bloom_hits Total bloom filter positive hits"
        lines << "# TYPE fast_exists_bloom_hits counter"
        lines << "fast_exists_bloom_hits #{stats[:bloom_hits]}"

        lines << "# HELP fast_exists_false_positives Total false positive bloom filter hits"
        lines << "# TYPE fast_exists_false_positives counter"
        lines << "fast_exists_false_positives #{stats[:false_positives]}"

        lines << "# HELP fast_exists_hit_ratio Bloom filter hit ratio"
        lines << "# TYPE fast_exists_hit_ratio gauge"
        lines << "fast_exists_hit_ratio #{stats[:hit_ratio]}"

        lines.join("\n")
      end
    end
  end
end
