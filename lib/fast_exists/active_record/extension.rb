# frozen_string_literal: true

module FastExists
  module ActiveRecord
    module Extension
      def self.included(base)
        base.extend(ClassMethods)
      end

      module ClassMethods
        def fast_exists(*attributes)
          options = attributes.extract_options!

          class_attribute :fast_exists_attributes, default: {} unless respond_to?(:fast_exists_attributes)

          attributes.map(&:to_sym).each do |attr|
            self.fast_exists_attributes = fast_exists_attributes.merge(attr => options)

            # Generate attribute_exists?(val)
            singleton_class.define_method("#{attr}_exists?") do |value|
              fast_exists?(attr, value)
            end

            # Generate attribute_available?(val)
            singleton_class.define_method("#{attr}_available?") do |value|
              fast_available?(attr, value)
            end
          end

          extend FastExists::ActiveRecord::ModelMethods
          include FastExists::ActiveRecord::Hooks
        end
      end
    end
  end
end
