# frozen_string_literal: true

module FastExists
  module Instrumentation
    class EventSubscriber
      EVENTS = %w[
        fast_exists.lookup
        fast_exists.hit
        fast_exists.miss
        fast_exists.false_positive
        fast_exists.database_lookup
      ].freeze

      def self.subscribe!
        return unless defined?(ActiveSupport::Notifications)

        EVENTS.each do |event_name|
          ActiveSupport::Notifications.subscribe(event_name) do |name, start, finish, id, payload|
            # Can log or forward metrics
          end
        end
      end

      def self.instrument(event_name, payload = {})
        if defined?(ActiveSupport::Notifications) && FastExists.configuration.instrumentation
          ActiveSupport::Notifications.instrument("fast_exists.#{event_name}", payload) do
            yield if block_given?
          end
        elsif block_given?
          yield
        end
      end
    end
  end
end
