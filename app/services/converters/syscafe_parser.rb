module Converters
  class SyscafeParser
    attr_reader :employees, :period_info

    PERIOD_ROW = 5
    HEADER_ROW = 7
    DATA_START_ROW = 8

    # Maps header text patterns to internal field names
    HEADER_PATTERNS = {
      /\Aidentificaci/i => :document_number,
      /\Acontrato\z/i => :contract_number,
      /\Anombre\z/i => :name,
      /\Acargo\z/i => :position,
      /\Abasico\z/i => :basic_salary,
      /\Adiaslabo/i => :worked_days,
      /\Adiasvaca/i => :vacation_days,
      /\Adiasinca?/i => :sick_days,
      /\Asueldo\z/i => :salary,
      /auxilio de transporte/i => :transport_aid,
      /cesantias liquidadas/i => :severance_liquidated,
      /vacaciones liquidadas/i => :vacation_liquidated,
      /prima liquidada/i => :bonus_liquidated,
      /interes.*cesantias/i => :severance_interest_liquidated,
      /\Atotal devengado/i => :total_earned,
      /\Aprestamos/i => :loans,
      /salud trabajador/i => :health_employee,
      /pension trabajador/i => :pension_employee,
      /\Atotal deducido/i => :total_deducted,
      /neto a pagar/i => :net_pay,
      /\Aauxilio\z/i => :other_aid
    }.freeze

    THIRD_PARTY_PREFIXES = %w[
      COMPENSAR PENSIONES ADMINISTRADORA SEGUROS SALUD ARL
      CAJA PENSION RIESGOS
    ].freeze

    def initialize(file)
      @file = file
      @employees = []
      @period_info = {}
    end

    def parse
      spreadsheet = Roo::Spreadsheet.open(@file)

      extract_period_info(spreadsheet.sheet(0))

      spreadsheet.sheets.each do |sheet_name|
        sheet = spreadsheet.sheet(sheet_name)
        next if sheet.last_row.nil? || sheet.last_row < DATA_START_ROW

        col_map = parse_header(sheet)
        next if col_map.empty?

        extract_employees_from_sheet(sheet, col_map)
      end

      Rails.logger.info "=== SyscafeParser: Found #{@employees.length} employees across #{spreadsheet.sheets.length} sheets"

      self
    end

    private

    def extract_period_info(sheet)
      period_cell = sheet.cell(PERIOD_ROW, 1).to_s
      matches = period_cell.scan(/"([^"]+)"/)

      if matches.length >= 3
        # Find the NM (nomina) reference if multiple periods exist
        nm_index = matches.index { |m| m[0].strip.start_with?("NM") }

        if nm_index
          @period_info[:reference] = matches[nm_index][0].strip
          @period_info[:end_date] = parse_syscafe_date(matches[nm_index + 1][0].strip)
          @period_info[:start_date] = parse_syscafe_date(matches[nm_index + 2][0].strip)
        else
          @period_info[:reference] = matches[0][0].strip
          @period_info[:end_date] = parse_syscafe_date(matches[1][0].strip)
          @period_info[:start_date] = parse_syscafe_date(matches[2][0].strip)
        end
      end

      @period_info[:company_name] = sheet.cell(1, 1).to_s.strip
      @period_info[:company_nit] = sheet.cell(2, 1).to_s.strip.gsub(/^NIT\.\s*/, "")
    end

    def parse_header(sheet)
      col_map = {}
      (1..sheet.last_column).each do |col|
        header = sheet.cell(HEADER_ROW, col).to_s.strip
        next if header.empty?

        HEADER_PATTERNS.each do |pattern, field|
          if header.match?(pattern)
            col_map[field] = col
            break
          end
        end
      end
      col_map
    end

    def extract_employees_from_sheet(sheet, col_map)
      doc_col = col_map[:document_number] || 1

      row = DATA_START_ROW
      while row <= sheet.last_row
        id_str = sheet.cell(row, doc_col).to_s.strip

        if employee_row?(id_str, sheet, row, col_map)
          employee = build_employee(sheet, row, id_str, col_map)
          parse_concepts_for(sheet, row, employee, col_map)
          @employees << employee
        end

        row += 1
      end
    end

    def employee_row?(id_str, sheet, row, col_map)
      return false unless id_str.match?(/\A\d{5,}\z/)

      salary_col = col_map[:salary] || col_map[:basic_salary]
      return false unless salary_col

      salary = sheet.cell(row, salary_col)
      return false unless salary.is_a?(Numeric) && salary > 0

      name_col = col_map[:name]
      if name_col
        name = sheet.cell(row, name_col).to_s.strip
      else
        name = find_name_value(sheet, row)
      end
      return false if name.blank?

      first_word = name.upcase.split.first
      return false if THIRD_PARTY_PREFIXES.include?(first_word)

      true
    end

    def build_employee(sheet, row, id_str, col_map)
      name_full = if col_map[:name]
        sheet.cell(row, col_map[:name]).to_s.strip
      else
        find_name_value(sheet, row)
      end

      names = parse_name(name_full)

      employee = {
        document_number: id_str,
        first_surname: names[:first_surname],
        second_surname: names[:second_surname],
        first_name: names[:first_name],
        other_names: names[:other_names],
        position: col_map[:position] ? sheet.cell(row, col_map[:position]).to_s.strip : "",
        basic_salary: to_number(cell_at(sheet, row, col_map, :basic_salary)),
        worked_days: to_number(cell_at(sheet, row, col_map, :worked_days)),
        vacation_days: to_number(cell_at(sheet, row, col_map, :vacation_days)),
        sick_days: to_number(cell_at(sheet, row, col_map, :sick_days)),
        salary: to_number(cell_at(sheet, row, col_map, :salary)),
        transport_aid: to_number(cell_at(sheet, row, col_map, :transport_aid)),
        total_earned: to_number(cell_at(sheet, row, col_map, :total_earned)),
        loans: to_number(cell_at(sheet, row, col_map, :loans)),
        health_employee: to_number(cell_at(sheet, row, col_map, :health_employee)),
        pension_employee: to_number(cell_at(sheet, row, col_map, :pension_employee)),
        total_deducted: to_number(cell_at(sheet, row, col_map, :total_deducted)),
        net_pay: to_number(cell_at(sheet, row, col_map, :net_pay)),
        concepts: {},
        third_parties: []
      }

      # Extract concept values from columns if present in this sheet
      if col_map[:vacation_liquidated]
        val = to_number(cell_at(sheet, row, col_map, :vacation_liquidated))
        employee[:concepts]["002"] = val if val > 0
      end

      if col_map[:bonus_liquidated]
        val = to_number(cell_at(sheet, row, col_map, :bonus_liquidated))
        employee[:concepts]["003"] = val if val > 0
      end

      if col_map[:severance_liquidated]
        val = to_number(cell_at(sheet, row, col_map, :severance_liquidated))
        employee[:concepts]["004"] = val if val > 0
      end

      if col_map[:other_aid]
        val = to_number(cell_at(sheet, row, col_map, :other_aid))
        employee[:other_aid] = val if val > 0
      end

      if col_map[:severance_interest_liquidated]
        val = to_number(cell_at(sheet, row, col_map, :severance_interest_liquidated))
        employee[:concepts]["014"] = val if val > 0
      end

      # Calculate missing totals if not in columns
      if employee[:total_deducted] == 0 && (employee[:health_employee] > 0 || employee[:loans] > 0)
        employee[:total_deducted] = employee[:health_employee] + employee[:pension_employee] + employee[:loans]
      end

      if employee[:net_pay] == 0 && employee[:total_earned] > 0
        employee[:net_pay] = employee[:total_earned] - employee[:total_deducted]
      end

      employee
    end

    def cell_at(sheet, row, col_map, field)
      col = col_map[field]
      col ? sheet.cell(row, col) : nil
    end

    def parse_concepts_for(sheet, employee_row, employee, col_map)
      # Only parse concept rows if the sheet doesn't have concept columns
      has_concept_columns = col_map.key?(:vacation_liquidated) ||
                            col_map.key?(:bonus_liquidated) ||
                            col_map.key?(:severance_liquidated)
      return if has_concept_columns

      doc_col = col_map[:document_number] || 1
      row = employee_row + 1
      while row <= sheet.last_row
        cell = sheet.cell(row, doc_col).to_s.strip
        break if employee_row?(cell, sheet, row, col_map)

        # "TOTAL->" marks end of employees section — CONCEPTO after this is a sheet summary, not per-employee
        col2 = sheet.cell(row, 2).to_s.strip
        break if col2.start_with?("TOTAL")

        if cell == "CONCEPTO"
          row = parse_concept_rows(sheet, row + 1, employee)
          break
        end

        row += 1
      end
    end

    def parse_concept_rows(sheet, start_row, employee)
      row = start_row
      while row <= sheet.last_row
        cell = sheet.cell(row, 1).to_s.strip
        break if cell.empty? || cell == "NIT"

        employee[:concepts][cell] = to_number(sheet.cell(row, 3))
        row += 1
      end

      if sheet.cell(row, 1).to_s.strip == "NIT"
        parse_third_parties(sheet, row + 1, employee)
      end

      row
    end

    def parse_third_parties(sheet, start_row, employee)
      row = start_row
      while row <= sheet.last_row
        nit = sheet.cell(row, 1).to_s.strip
        break if nit.empty?

        employee[:third_parties] << {
          nit: nit,
          name: sheet.cell(row, 2).to_s.strip,
          value: to_number(sheet.cell(row, 3))
        }
        row += 1
      end
    end

    def find_name_value(sheet, row)
      col2 = sheet.cell(row, 2).to_s.strip
      return col2 if col2.present? && !col2.match?(/^\d+-\d+$/)

      col3 = sheet.cell(row, 3).to_s.strip
      return col3 if col3.present? && !col3.match?(/^\d+-\d+$/)

      ""
    end

    def parse_name(name_full)
      return { first_surname: "", second_surname: "", first_name: "", other_names: "" } if name_full.blank?

      clean_name = name_full.sub(/^\d+-/, "").strip
      return { first_surname: "", second_surname: "", first_name: clean_name, other_names: "" } unless clean_name.include?(" ")

      parts = clean_name.split(/\s+/).reject(&:empty?)
      {
        first_surname: parts[0] || "",
        second_surname: parts[1] || "",
        first_name: parts[2] || "",
        other_names: parts[3..].to_a.join(" ")
      }
    end

    def parse_syscafe_date(date_str)
      return nil if date_str.blank?
      parts = date_str.split("-")
      return nil if parts.length != 3
      "#{parts[2]}-#{parts[0]}-#{parts[1]}"
    rescue
      nil
    end

    def to_number(value)
      return 0 if value.nil?
      value.is_a?(Numeric) ? value.to_i : value.to_s.gsub(/[^\d.-]/, "").to_i
    end
  end
end
