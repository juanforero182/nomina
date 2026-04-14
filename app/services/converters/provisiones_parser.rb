module Converters
  class ProvisionesParser
    HEADER_ROW = 5
    DOC_COL = 3
    CONCEPT_COL = 7
    FIRST_MONTH_COL = 9 # Enero
    TRACKED_CONCEPTS = %w[953 954 955 956].freeze

    def initialize(file, month)
      @file = file
      @month = month.to_i
    end

    def parse
      return {} unless @file && (1..12).include?(@month)

      month_col = FIRST_MONTH_COL + (@month - 1)
      sheet = Roo::Spreadsheet.open(@file).sheet(0)
      result = {}

      (HEADER_ROW + 1..sheet.last_row).each do |row|
        doc = sheet.cell(row, DOC_COL).to_s.strip
        concept = sheet.cell(row, CONCEPT_COL).to_s.strip
        next if doc.empty? || !TRACKED_CONCEPTS.include?(concept)

        value = sheet.cell(row, month_col)
        numeric = value.is_a?(Numeric) ? value.to_i : value.to_s.gsub(/[^\d.-]/, "").to_i
        next if numeric <= 0

        result[doc] ||= {}
        result[doc][concept] = numeric
      end

      result
    end
  end
end
