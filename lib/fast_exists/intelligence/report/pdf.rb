# frozen_string_literal: true

module FastExists
  module Intelligence
    module Report
      class Pdf
        def self.render(data, comparison: nil)
          # Formats executive PDF-compatible markdown/text report
          lines = []
          lines << "% FAST_EXISTS PERFORMANCE & ARCHITECTURE REPORT"
          lines << "% Executive Summary"
          lines << "% Date: #{data.timestamp}"
          lines << ""
          lines << "================================================================================"
          lines << "OVERALL OPERATIONAL HEALTH: #{data.health[:overall_status].to_s.upcase}"
          lines << "ARCHITECTURAL GRADE: #{data.audit[:grade]} (Score: #{data.audit[:audit_score]}/100)"
          lines << "QUERIES AVOIDED BY BLOOM FILTERS: #{data.stats[:queries_avoided]}"
          lines << "================================================================================"
          lines << ""
          lines << "1. APPLICATION & ENVIRONMENT"
          lines << "   - Ruby Version: #{data.environment[:ruby_version]}"
          lines << "   - Rails Version: #{data.environment[:rails_version]}"
          lines << "   - DB Adapter: #{data.environment[:database_adapter]}"
          lines << "   - Backend Storage: #{data.environment[:backend]}"
          lines << ""
          lines << "2. HEALTH DIAGNOSTICS"
          data.health[:checks].each do |c|
            lines << "   - [#{c[:status].to_s.upcase}] #{c[:name]}: #{c[:message]}"
          end
          lines << ""
          lines << "3. AUDIT & DOCTOR RECOMMENDATIONS"
          data.audit[:findings].each do |f|
            lines << "   * Location: #{f[:location]}"
            lines << "     Severity: #{f[:severity].to_s.upcase}"
            lines << "     Problem: #{f[:problem]}"
            lines << "     Recommendation: #{f[:recommendation]}"
          end
          lines.join("\n")
        end
      end
    end
  end
end
