# frozen_string_literal: true

module FastExists
  module MultiTenant
    module Strategies
      class SharedStrategy < BaseStrategy
        attr_reader :pools

        def initialize(options = {})
          super
          @pools = {
            small: FastExists::MultiTenant::Pool.new(name: "small", expected_elements: 500_000),
            medium: FastExists::MultiTenant::Pool.new(name: "medium", expected_elements: 2_000_000),
            large: FastExists::MultiTenant::Pool.new(name: "large", expected_elements: 10_000_000)
          }
        end

        def add(tenant_id, attribute, value)
          pool = pool_for(tenant_id)
          pool.add(tenant_id, attribute, value)
        end

        def contains?(tenant_id, attribute, value)
          pool = pool_for(tenant_id)
          pool.contains?(tenant_id, attribute, value)
        end

        def classify_tenant(_tenant_id, record_count)
          case record_count
          when 0..100_000 then :small
          when 100_001..1_000_000 then :medium
          else :large
          end
        end

        def stats
          {
            strategy: :shared,
            pools: @pools.transform_values(&:stats)
          }
        end

        private

        def pool_for(tenant_id)
          # Default to medium pool if unclassified
          @pools[:medium]
        end
      end
    end
  end
end
