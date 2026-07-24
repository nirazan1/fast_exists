# frozen_string_literal: true

module FastExists
  module ActiveRecord
    module Hooks
      def self.included(base)
        base.after_commit :fast_exists_sync_on_commit, on: [:create, :update]
      end

      private

      def fast_exists_sync_on_commit
        return unless FastExists.configuration.auto_sync

        self.class.fast_exists_attributes.each do |attr, options|
          val = send(attr)
          next if val.nil? || val.to_s.strip.empty?

          backend = self.class.fast_exists_backend_for(attr)
          backend.add(val.to_s)
        end
      end
    end
  end
end
