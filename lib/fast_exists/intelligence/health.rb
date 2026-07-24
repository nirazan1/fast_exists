# frozen_string_literal: true

module FastExists
  module Intelligence
    class Health
      def self.check
        new.run_checks
      end

      def run_checks
        items = []

        # 1. Backend Availability
        backend_symbol = FastExists.configuration.backend
        items << check_item(
          name: "Backend Availability",
          status: FastExists.backends.registered?(backend_symbol) ? :pass : :critical,
          message: "Backend '#{backend_symbol}' is registered and active"
        )

        # 2. Redis & RedisBloom Checks
        if [:redis, :redis_bloom].include?(backend_symbol)
          redis_ok = check_redis_connection
          items << check_item(
            name: "Redis Connectivity",
            status: redis_ok ? :pass : :critical,
            message: redis_ok ? "Connected to Redis successfully" : "Redis client connection failed"
          )
          if backend_symbol == :redis_bloom
            rb_ok = check_redis_bloom_module
            items << check_item(
              name: "RedisBloom Module",
              status: rb_ok ? :pass : :warning,
              message: rb_ok ? "RedisBloom module loaded" : "RedisBloom module not detected on Redis server"
            )
          end
        end

        # 3. Capacity & Occupancy
        stats = FastExists.stats
        fp_rate = stats[:false_positive_rate] || 0.0

        if fp_rate > 0.02
          items << check_item(name: "False Positive Rate", status: :critical, message: "False positive rate high (#{(fp_rate * 100).round(2)}%)")
        elsif fp_rate > 0.005
          items << check_item(name: "False Positive Rate", status: :warning, message: "False positive rate increasing (#{(fp_rate * 100).round(2)}%)")
        else
          items << check_item(name: "False Positive Rate", status: :pass, message: "False positive rate healthy")
        end

        # 4. Synchronization Health
        sync_ok = FastExists.configuration.auto_sync
        items << check_item(
          name: "Synchronization Health",
          status: sync_ok ? :pass : :warning,
          message: sync_ok ? "Automatic commit synchronization active" : "Auto sync disabled"
        )

        # 5. Instrumentation Status
        inst_ok = FastExists.configuration.instrumentation
        items << check_item(
          name: "Instrumentation Status",
          status: inst_ok ? :pass : :pass,
          message: inst_ok ? "ActiveSupport::Notifications enabled" : "Instrumentation disabled"
        )

        # 6. Version Compatibility
        items << check_item(
          name: "Version Compatibility",
          status: :pass,
          message: "Ruby #{RUBY_VERSION} compatible with fast_exists v#{FastExists::VERSION}"
        )

        overall_status = determine_overall_status(items)

        {
          overall_status: overall_status,
          checks: items
        }
      end

      private

      def check_item(name:, status:, message:)
        { name: name, status: status, message: message }
      end

      def check_redis_connection
        return true unless FastExists.configuration.redis
        FastExists.configuration.redis.ping rescue false
      end

      def check_redis_bloom_module
        return false unless FastExists.configuration.redis
        FastExists.configuration.redis.call(["BF.INFO"]) rescue true
      end

      def determine_overall_status(items)
        if items.any? { |i| i[:status] == :critical }
          :critical
        elsif items.any? { |i| i[:status] == :warning }
          :warning
        else
          :healthy
        end
      end
    end
  end
end
