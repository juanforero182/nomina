module Converters
  class SyscafeDirectoryParser
    attr_reader :entries, :company_info

    HEADER_ROW = 5
    DATA_START_ROW = 6

    CONTRACT_TYPE_MAP = {
      "LEY 50" => 2,
      "TERMINO FIJO" => 1,
      "OBRA LABOR" => 3,
      "APRENDIZAJE" => 4,
      "PRACTICAS" => 5
    }.freeze

    def initialize(file)
      @file = file
      @entries = []
      @company_info = {}
    end

    def parse
      spreadsheet = Roo::Spreadsheet.open(@file)
      sheet = spreadsheet.sheet(0)

      extract_company_info(sheet)
      extract_entries(sheet)

      self
    end

    private

    def extract_company_info(sheet)
      @company_info[:name] = sheet.cell(1, 1).to_s.strip
      @company_info[:nit] = sheet.cell(2, 1).to_s.strip.gsub(/^NIT\.\s*/, "")
    end

    def extract_entries(sheet)
      row = DATA_START_ROW
      while row <= sheet.last_row
        doc_number = sheet.cell(row, 1).to_s.strip

        if doc_number.match?(/\A\d{5,}\z/)
          @entries << build_entry(sheet, row, doc_number)
        end

        row += 1
      end
    end

    def build_entry(sheet, row, doc_number)
      name_full = sheet.cell(row, 2).to_s.strip
      names = parse_name(name_full)
      contract_text = sheet.cell(row, 24).to_s.strip

      {
        employee: {
          document_number: doc_number,
          first_surname: names[:first_surname],
          second_surname: names[:second_surname],
          first_name: names[:first_name],
          other_names: names[:other_names],
          phone: sheet.cell(row, 4).to_s.strip.presence,
          mobile: sheet.cell(row, 5).to_s.strip.presence,
          gender: sheet.cell(row, 6).to_s.strip.presence,
          address: sheet.cell(row, 7).to_s.strip.presence,
          email: sheet.cell(row, 8).to_s.strip.presence
        },
        contract: {
          contract_number: sheet.cell(row, 3).to_s.strip.presence,
          health_entity: sheet.cell(row, 9).to_s.strip.presence,
          health_date: parse_date(sheet.cell(row, 10)),
          pension_entity: sheet.cell(row, 11).to_s.strip.presence,
          pension_date: parse_date(sheet.cell(row, 12)),
          arl_entity: sheet.cell(row, 13).to_s.strip.presence,
          arl_date: parse_date(sheet.cell(row, 14)),
          compensation_fund: sheet.cell(row, 15).to_s.strip.presence,
          severance_fund: sheet.cell(row, 16).to_s.strip.presence,
          contract_date: parse_date(sheet.cell(row, 17)),
          contract_end_date: parse_date(sheet.cell(row, 18)),
          vacation_date: parse_date(sheet.cell(row, 19)),
          status: parse_status(sheet.cell(row, 20)),
          basic_salary: parse_number(sheet.cell(row, 21)),
          area: sheet.cell(row, 22).to_s.strip.presence,
          position: sheet.cell(row, 23).to_s.strip.presence,
          contract_type: map_contract_type(contract_text),
          bank_account: sheet.cell(row, 25).to_s.strip.presence,
          bank_name: sheet.cell(row, 26).to_s.strip.presence
        }
      }
    end

    def parse_name(name_full)
      parts = name_full.split(/\s+/).reject(&:empty?)
      {
        first_surname: parts[0] || "",
        second_surname: parts[1] || "",
        first_name: parts[2] || "",
        other_names: parts[3..].to_a.join(" ")
      }
    end

    def parse_date(value)
      return nil if value.nil?

      if value.is_a?(Date) || value.is_a?(DateTime)
        value.to_date
      elsif value.is_a?(Numeric)
        Date.new(1899, 12, 30) + value.to_i
      else
        date_str = value.to_s.strip
        return nil if date_str.empty?
        Date.strptime(date_str, "%d/%m/%Y")
      end
    rescue ArgumentError
      nil
    end

    def parse_number(value)
      return nil if value.nil?
      value.is_a?(Numeric) ? value : value.to_s.gsub(/[^\d.]/, "").to_f
    end

    def parse_status(value)
      value.to_s.strip.upcase == "ACTIVO" ? "active" : "inactive"
    end

    def map_contract_type(text)
      CONTRACT_TYPE_MAP[text.upcase] || 3
    end
  end
end
