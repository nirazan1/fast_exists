# frozen_string_literal: true

module FastExists
  module Optimizer
    class AiAdvisor
      def self.analyze(model_class = nil, attribute = nil)
        stats = FastExists.stats
        db_count = model_class ? (model_class.count rescue 100_000) : 100_000

        recommended_fp = stats[:false_positive_rate] > 0.01 ? 0.001 : 0.0005
        recommended_capacity = (db_count * 1.5).ceil

        # Optimal m calculation: m = - (n * ln(p)) / (ln(2)^2)
        optimal_bits = (-(recommended_capacity * Math.log(recommended_fp)) / (Math.log(2)**2)).ceil
        optimal_hashes = [((optimal_bits.to_f / recommended_capacity) * Math.log(2)).round, 1].max

        recommended_backend = case db_count
                              when 0..100_000 then :memory
                              when 100_001..5_000_000 then :redis
                              else :redis_bloom
                              end

        {
          current_stats: stats,
          recommendations: {
            false_positive_rate: recommended_fp,
            expected_elements: recommended_capacity,
            optimal_bit_size: optimal_bits,
            optimal_hash_count: optimal_hashes,
            recommended_backend: recommended_backend,
            estimated_memory_mb: (optimal_bits / 8.0 / 1_048_576.0).round(2),
            advice: generate_advice(stats, db_count, recommended_backend)
          }
        }
      end

      private

      def self.generate_advice(stats, db_count, backend)
        adv = []
        if stats[:false_positive_rate] > 0.01
          adv << "False positive rate is high (#{stats[:false_positive_rate] * 100}%). Increase expected_elements or reduce false_positive_rate target."
        end
        if stats[:hit_ratio] > 0.8
          adv << "High Bloom filter hit ratio (#{stats[:hit_ratio] * 100}%). Most lookups are positive. Check if existence queries are necessary before writing."
        end
        adv << "Recommended backend for dataset of #{db_count} records is :#{backend}."
        adv.join(" ")
      end
    end
  end
end
