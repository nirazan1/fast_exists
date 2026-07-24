# frozen_string_literal: true

module FastExists
  module MultiTenant
    module Strategies
      class AdaptiveStrategy < BaseStrategy
        attr_reader :pools, :per_tenant_strategy

        def initialize(options = {})
          super
          @thresholds = options[:thresholds] || FastExists.configuration.tenant_thresholds
          @pools = {
            tiny: FastExists::MultiTenant::Pool.new(name: "tiny", expected_elements: 200_000),
            small: FastExists::MultiTenant::Pool.new(name: "small", expected_elements: 1_000_000),
            medium: FastExists::MultiTenant::Pool.new(name: "medium", expected_elements: 5_000_000)
          }
          @per_tenant_strategy = FastExists::MultiTenant::Strategies::PerTenantStrategy.new(options)
          @tenant_classification_cache = {}
          @mutex = Mutex.new
        end

        def add(tenant_id, attribute, value)
          category = tenant_category(tenant_id)
          if category == :large
            @per_tenant_strategy.add(tenant_id, attribute, value)
          else
            pool = @pools[category] || @pools[:tiny]
            pool.add(tenant_id, attribute, value)
          end
        end

        def contains?(tenant_id, attribute, value)
          category = tenant_category(tenant_id)
          if category == :large
            @per_tenant_strategy.contains?(tenant_id, attribute, value)
          else
            pool = @pools[category] || @pools[:tiny]
            pool.contains?(tenant_id, attribute, value)
          end
        end

        def classify_tenant(_tenant_id, record_count)
          tiny_max = @thresholds[:tiny] || 10_000
          small_max = @thresholds[:small] || 100_000
          medium_max = @thresholds[:medium] || 1_000_000

          case record_count
          when 0...tiny_max then :tiny
          when tiny_max...small_max then :small
          when small_max...medium_max then :medium
          else :large
          end
        end

        def set_tenant_category(tenant_id, category)
          @mutex.synchronize do
            @tenant_classification_cache[tenant_id.to_s] = category.to_sym
          end
        end

        def tenant_category(tenant_id)
          @mutex.synchronize do
            @tenant_classification_cache[tenant_id.to_s] || :tiny
          end
        end

        def stats
          @mutex.synchronize do
            {
              strategy: :adaptive,
              classified_tenants: @tenant_classification_cache.size,
              distribution: @tenant_classification_cache.values.tally,
              pools: @pools.transform_values(&:stats),
              dedicated_filters: @per_tenant_strategy.stats
            }
          end
        end
      end
    end
  end
end
