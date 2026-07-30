# frozen_string_literal: true

module FastExists
  module Intelligence
    class Auditor
      def self.audit
        new.run_audit
      end

      def run_audit
        findings = []

        # 1. Inspect ActiveRecord Models & Indexes
        if defined?(::ActiveRecord::Base)
          ::ActiveRecord::Base.descendants.reject(&:abstract_class?).each do |klass|
            next unless klass.respond_to?(:table_exists?) && klass.table_exists?
            inspect_model(klass, findings)
          end
        end

        # 2. Inspect Backend Configuration
        inspect_configuration(findings)

        # 3. Calculate Audit Score & Grade
        score = calculate_audit_score(findings)
        grade = determine_grade(score)

        {
          audit_score: score,
          grade: grade,
          findings: findings
        }
      end

      private

      def inspect_model(klass, findings)
        indexes = klass.connection.indexes(klass.table_name) rescue []

        # Check unique validations vs database indexes
        klass.validators.each do |validator|
          is_uniqueness = begin validator.class.name.include?("UniquenessValidator") rescue false end
          if is_uniqueness
            attributes = validator.attributes
            attributes.each do |attr|
              has_unique_index = indexes.any? { |idx| idx.unique && idx.columns.include?(attr.to_s) }
              unless has_unique_index
                findings << {
                  severity: :critical,
                  location: "#{klass.name}##{attr}",
                  problem: "Missing unique database index on uniquely validated attribute '#{attr}'",
                  reason: "Uniqueness validation without a unique index risks race conditions and slow existence lookups",
                  recommendation: "Add a unique index migration for #{klass.table_name}.#{attr}",
                  estimated_impact: "High (Prevents DB race conditions & accelerates existence checks)"
                }
              end
            end
          end
        end

        # Check for fast_exists attributes that lack index
        if klass.respond_to?(:fast_exists_attributes)
          klass.fast_exists_attributes.each do |attr, _options|
            has_index = indexes.any? { |idx| idx.columns.include?(attr.to_s) }
            unless has_index
              findings << {
                severity: :warning,
                location: "#{klass.name}##{attr}",
                problem: "FastExists attribute '#{attr}' is not indexed in database",
                reason: "When a Bloom filter positive hit occurs, falling back to an un-indexed DB query causes table scans",
                recommendation: "Create an index on #{klass.table_name}(#{attr})",
                estimated_impact: "Medium (Eliminates table scans on Bloom filter hits)"
              }
            end
          end
        end
      end

      def inspect_configuration(findings)
        cfg = FastExists.configuration
        if cfg.backend == :memory && defined?(Rails) && Rails.env.production?
          findings << {
            severity: :warning,
            location: "config/initializers/fast_exists.rb",
            problem: "In-memory backend used in multi-process production environment",
            reason: "In-memory filters are isolated per Puma worker process and lost on restart",
            recommendation: "Configure config.backend = :redis or :redis_bloom for production environments",
            estimated_impact: "High (Enables distributed filter synchronization across workers)"
          }
        end
      end

      def calculate_audit_score(findings)
        base = 100
        findings.each do |f|
          case f[:severity]
          when :critical then base -= 15
          when :warning  then base -= 5
          when :info     then base -= 2
          end
        end
        [base, 0].max
      end

      def determine_grade(score)
        case score
        when 90..100 then "A"
        when 80..89  then "B"
        when 70..79  then "C"
        when 60..69  then "D"
        else "F"
        end
      end
    end
  end
end
