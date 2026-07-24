# frozen_string_literal: true

module FastExists
  module ActiveRecord
    module ModelMethods
      def fast_exists?(*args)
        attribute, value = args.size == 2 ? args : [fast_exists_attributes.keys.first, args.first]
        attribute = attribute.to_sym
        raise InvalidArgumentError, "Attribute #{attribute} is not configured with fast_exists" unless fast_exists_attributes.key?(attribute)

        backend = fast_exists_backend_for(attribute)
        str_val = value.to_s

        FastExists::Instrumentation::EventSubscriber.instrument(:lookup, model: name, attribute: attribute, value: str_val)

        # Check probabilistic filter
        if backend.contains?(str_val)
          FastExists.stats_tracker.record_hit
          FastExists.stats_tracker.record_db_lookup

          # DB check
          exists_in_db = where(attribute => value).exists?

          if exists_in_db
            FastExists::Instrumentation::EventSubscriber.instrument(:hit, model: name, attribute: attribute, value: str_val)
            true
          else
            FastExists.stats_tracker.record_false_positive
            FastExists::Instrumentation::EventSubscriber.instrument(:false_positive, model: name, attribute: attribute, value: str_val)
            false
          end
        else
          FastExists.stats_tracker.record_avoided
          FastExists::Instrumentation::EventSubscriber.instrument(:miss, model: name, attribute: attribute, value: str_val)
          false
        end
      end

      def fast_available?(attribute, value = nil)
        if value.nil?
          value = attribute
          attribute = fast_exists_attributes.keys.first
        end
        !fast_exists?(attribute, value)
      end

      def rebuild_fast_exists!(attribute = nil)
        attributes_to_rebuild = attribute ? [attribute.to_sym] : fast_exists_attributes.keys

        attributes_to_rebuild.each do |attr|
          backend = fast_exists_backend_for(attr)
          backend.clear

          if respond_to?(:find_in_batches)
            find_in_batches(batch_size: 5000) do |batch|
              batch.each do |record|
                val = record.send(attr)
                backend.add(val.to_s) if val.present?
              end
            end
          else
            pluck(attr).compact.each do |val|
              backend.add(val.to_s)
            end
          end
          backend.save if backend.respond_to?(:save)
        end
        true
      end

      def rebuild_fast_exists_async!(attribute = nil)
        if defined?(Sidekiq)
          # Asynchronous sidekiq dispatch
          FastExists::Jobs::RebuildJob.perform_async(name, attribute&.to_s)
        else
          rebuild_fast_exists!(attribute)
        end
      end

      def fast_exists_stats(attribute = nil)
        attributes = attribute ? [attribute.to_sym] : fast_exists_attributes.keys
        stats_hash = {}

        attributes.each do |attr|
          backend = fast_exists_backend_for(attr)
          stats_hash[attr] = backend.stats.merge(global_stats: FastExists.stats)
        end

        attribute ? stats_hash[attribute.to_sym] : stats_hash
      end

      def fast_exists_backend_for(attribute)
        @fast_exists_backends ||= {}
        @fast_exists_backends[attribute.to_sym] ||= begin
          options = fast_exists_attributes[attribute.to_sym] || {}
          backend_name = options[:backend] || FastExists.configuration.backend
          namespace = options[:namespace] || "#{name.underscore}:#{attribute}"

          resolved_ns = FastExists::MultiTenancy::Resolver.resolve(namespace)

          FastExists.backends.fetch(
            backend_name,
            options.merge(namespace: resolved_ns)
          )
        end
      end
    end
  end
end
