# frozen_string_literal: true

require "fileutils"

module FastExists
  module Intelligence
    module Report
      class Builder
        def self.build(format: :console, output: nil, include: nil, compare: nil)
          data = FastExists::Intelligence::DataModel.new
          data.health = FastExists::Intelligence::Health.check
          data.analysis = FastExists::Intelligence::Analyzer.analyze
          data.audit = FastExists::Intelligence::Auditor.audit
          data.doctor = FastExists::Intelligence::Doctor.diagnose(format: :json)

          comparison_data = load_comparison(compare) if compare

          rendered_content = case format.to_sym
                             when :json
                               FastExists::Intelligence::Report::Json.render(data, comparison: comparison_data)
                             when :yaml
                               FastExists::Intelligence::Report::Yaml.render(data, comparison: comparison_data)
                             when :markdown
                               FastExists::Intelligence::Report::Markdown.render(data, comparison: comparison_data)
                             when :html
                               FastExists::Intelligence::Report::Html.render(data, comparison: comparison_data)
                             when :csv
                               FastExists::Intelligence::Report::Csv.render(data, comparison: comparison_data)
                             when :pdf
                               FastExists::Intelligence::Report::Pdf.render(data, comparison: comparison_data)
                             else
                               FastExists::Intelligence::Report::Console.render(data, comparison: comparison_data)
                             end

          if output
            FileUtils.mkdir_p(File.dirname(output))
            File.write(output, rendered_content)
            puts "Report generated successfully at #{output}"
          end

          rendered_content
        end

        private

        def self.load_comparison(file_path)
          return nil unless file_path && File.exist?(file_path)
          JSON.parse(File.read(file_path), symbolize_names: true) rescue nil
        end
      end
    end
  end
end
