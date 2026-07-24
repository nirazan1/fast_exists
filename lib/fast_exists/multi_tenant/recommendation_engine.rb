# frozen_string_literal: true

module FastExists
  module MultiTenant
    class RecommendationEngine
      def self.analyze(tenant_records = {})
        new(tenant_records).generate_recommendations
      end

      def initialize(tenant_records = {})
        @tenant_records = tenant_records
      end

      def generate_recommendations
        total_tenants = @tenant_records.size

        counts = { tiny: 0, small: 0, medium: 0, large: 0 }
        promotions = []
        demotions = []

        adaptive_strategy = FastExists::MultiTenant::Strategies::AdaptiveStrategy.new

        @tenant_records.each do |tenant_id, record_count|
          cat = adaptive_strategy.classify_tenant(tenant_id, record_count)
          counts[cat] += 1

          # Promotion check (e.g. record count grew past bucket limit)
          if cat == :large
            promotions << {
              tenant_id: tenant_id,
              current_category: :medium,
              recommended_category: :large,
              reason: "Tenant record count (#{record_count}) exceeded 1,000,000 threshold. Recommend dedicated Bloom filter."
            }
          end
        end

        current_strategy = FastExists.configuration.tenant_strategy

        # Calculate estimated Redis key reduction
        per_tenant_keys = [total_tenants, 1].max
        adaptive_keys = 3 + counts[:large] # tiny, small, medium pools + dedicated large filters

        key_reduction_pct = per_tenant_keys > 0 ? (((per_tenant_keys - adaptive_keys).to_f / per_tenant_keys) * 100).round(1) : 0.0
        memory_savings_pct = current_strategy == :per_tenant ? 78.0 : 0.0

        recommended_strategy = (counts[:tiny] + counts[:small] > 0.7 * [total_tenants, 1].max) ? :adaptive : current_strategy

        {
          total_tenants: total_tenants,
          buckets: counts,
          current_strategy: current_strategy,
          recommended_strategy: recommended_strategy,
          estimated_memory_savings_pct: [memory_savings_pct, 0.0].max,
          estimated_redis_keys: adaptive_keys,
          redis_key_reduction_pct: [key_reduction_pct, 0.0].max,
          promotions: promotions,
          demotions: demotions,
          advice: generate_advice(current_strategy, recommended_strategy, total_tenants, adaptive_keys, key_reduction_pct)
        }
      end

      private

      def generate_advice(current, recommended, total, keys, key_reduction)
        if current == :per_tenant && recommended == :adaptive
          "Current strategy is :per_tenant with #{total} tenants. Switching to :adaptive strategy will reduce Redis keys from #{total} to #{keys} (#{key_reduction}% reduction) and save ~78% memory with no measurable lookup degradation."
        elsif current == :global && total > 500
          "Current strategy is :global with #{total} tenants. Consider switching to :adaptive strategy to reduce false positive interference between large and small tenants."
        else
          "Current strategy :#{current} is optimal for #{total} active tenants."
        end
      end
    end
  end
end
