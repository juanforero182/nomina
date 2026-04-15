require "csv"

module Converters
  class MinominaCsvGenerator
    TOTAL_COLUMNS = 162

    COLUMNS = {
      document_type: 0,
      document_number: 1,
      first_surname: 2,
      second_surname: 3,
      first_name: 4,
      other_names: 5,
      worker_type: 6,
      worker_subtype: 7,
      high_risk_pension: 8,
      country: 9,
      department: 10,
      municipality: 11,
      address: 12,
      integral_salary: 13,
      contract_type: 14,
      salary: 15,
      hire_date: 16,
      termination_date: 17,
      time_worked: 18,
      email: 19,
      notes: 20,
      voucher_total: 21,
      currency: 22,
      trm: 23,
      payroll_type: 24,
      settlement_start: 25,
      predecessor_number: 26,
      predecessor_cune: 27,
      predecessor_date: 28,
      worker_code: 29,
      prefix: 30,
      consecutive: 31,
      payment_form: 32,
      payment_method: 33,
      bank: 34,
      account_type: 35,
      account_number: 36,
      payment_date: 37,
      worked_days: 38,
      worked_salary: 39,
      transport_aid: 40,
      aid_value: 102,
      aid_is_salary: 103,
      aid_description: 104,
      vacation_compensated: 78,
      vacation_start: 79,
      vacation_end: 80,
      vacation_days: 81,
      vacation_payment: 82,
      bonus_days: 83,
      bonus_payment: 84,
      bonus_ns_payment: 85,
      severance_payment: 86,
      severance_percentage: 87,
      severance_interest: 88,
      health_percentage: 129,
      health_deduction: 130,
      pension_percentage: 131,
      pension_deduction: 132,
      other_deduction_desc: 148,
      other_deduction_value: 149,
      total_earned: 160,
      total_deducted: 161
    }.freeze

    DEFAULTS = {
      document_type: 13,
      worker_type: "01",
      worker_subtype: "00",
      high_risk_pension: "false",
      country: "CO",
      department: 11,
      municipality: 11001,
      address: "BOGOTA",
      integral_salary: "false",
      contract_type: 3,
      currency: "COP",
      payroll_type: 1,
      payment_form: 1,
      payment_method: 46,
      health_percentage: 4,
      pension_percentage: 4
    }.freeze

    def initialize(employees, period_info, provisions = {})
      @employees = employees
      @period_info = period_info
      @provisions = provisions || {}
    end

    def generate
      start = @period_info[:start_consecutive] || 1

      CSV.generate(force_quotes: false) do |csv|
        @employees.each_with_index do |employee, idx|
          consecutive = start + idx
          csv << sanitize_row(build_main_row(employee, consecutive))

          extra_row = build_extra_row(employee, consecutive)
          csv << sanitize_row(extra_row) if extra_row
        end
      end
    end

    def sanitize_row(row)
      row.map { |v| v.is_a?(String) ? v.tr(",", " ").squeeze(" ").strip : v }
    end

    private

    def build_main_row(employee, consecutive_num)
      row = Array.new(TOTAL_COLUMNS)

      row[COLUMNS[:document_type]] = format_number(employee[:document_type] || DEFAULTS[:document_type], 2)
      row[COLUMNS[:document_number]] = employee[:document_number]
      row[COLUMNS[:first_surname]] = employee[:first_surname].to_s.upcase
      row[COLUMNS[:second_surname]] = employee[:second_surname].to_s.upcase
      row[COLUMNS[:first_name]] = employee[:first_name].to_s.upcase
      row[COLUMNS[:other_names]] = employee[:other_names].to_s.upcase
      row[COLUMNS[:worker_type]] = DEFAULTS[:worker_type]
      row[COLUMNS[:worker_subtype]] = DEFAULTS[:worker_subtype]
      row[COLUMNS[:high_risk_pension]] = DEFAULTS[:high_risk_pension]
      row[COLUMNS[:country]] = DEFAULTS[:country]
      row[COLUMNS[:department]] = employee[:department] || DEFAULTS[:department]
      row[COLUMNS[:municipality]] = employee[:municipality] || DEFAULTS[:municipality]
      row[COLUMNS[:address]] = (employee[:address] || DEFAULTS[:address]).to_s.upcase
      row[COLUMNS[:integral_salary]] = employee[:integral_salary] || DEFAULTS[:integral_salary]
      row[COLUMNS[:contract_type]] = employee[:contract_type] || DEFAULTS[:contract_type]
      row[COLUMNS[:salary]] = employee[:basic_salary].to_i
      row[COLUMNS[:hire_date]] = employee[:hire_date]
      row[COLUMNS[:time_worked]] = calculate_time_worked(employee[:hire_date])
      row[COLUMNS[:voucher_total]] = employee[:net_pay].to_i
      row[COLUMNS[:currency]] = DEFAULTS[:currency]
      row[COLUMNS[:payroll_type]] = DEFAULTS[:payroll_type]
      row[COLUMNS[:settlement_start]] = @period_info[:start_date]
      prefix = extract_prefix
      row[COLUMNS[:worker_code]] = prefix[:code]
      row[COLUMNS[:prefix]] = prefix[:name]
      row[COLUMNS[:consecutive]] = consecutive_num
      row[COLUMNS[:payment_form]] = DEFAULTS[:payment_form]
      row[COLUMNS[:payment_method]] = DEFAULTS[:payment_method]
      row[COLUMNS[:payment_date]] = @period_info[:end_date]
      row[COLUMNS[:worked_days]] = employee[:worked_days].to_i
      row[COLUMNS[:worked_salary]] = employee[:salary].to_i
      transport = employee[:transport_aid].to_i
      if transport > 0
        row[COLUMNS[:transport_aid]] = transport
      elsif employee[:basic_salary].to_i <= 2_600_000
        row[COLUMNS[:transport_aid]] = 200_000
      end

      aid = employee[:other_aid].to_i
      if aid > 0
        row[COLUMNS[:aid_value]] = aid
        row[COLUMNS[:aid_is_salary]] = "false"
        row[COLUMNS[:aid_description]] = "AUXILIO"
      end

      row[COLUMNS[:health_percentage]] = DEFAULTS[:health_percentage]
      row[COLUMNS[:health_deduction]] = employee[:health_employee].to_i
      row[COLUMNS[:pension_percentage]] = DEFAULTS[:pension_percentage]
      row[COLUMNS[:pension_deduction]] = employee[:pension_employee].to_i

      if employee[:loans].to_i > 0
        row[COLUMNS[:other_deduction_desc]] = "PRESTAMOS"
        row[COLUMNS[:other_deduction_value]] = employee[:loans].to_i
      end

      row[COLUMNS[:total_earned]] = employee[:total_earned].to_i
      row[COLUMNS[:total_deducted]] = employee[:total_deducted].to_i

      row
    end

    def build_extra_row(employee, consecutive_num)
      prov = @provisions[employee[:document_number].to_s] || {}

      vacation_value = prov["955"].to_i
      bonus_value = prov["956"].to_i

      liquidated_severance = employee[:concepts]&.dig("004").to_i
      if liquidated_severance > 0
        severance_value = liquidated_severance
        severance_interest = (liquidated_severance * 0.12).round
      else
        severance_value = prov["953"].to_i
        severance_interest = prov["954"].to_i
      end

      return nil if vacation_value <= 0 && bonus_value <= 0 && severance_value <= 0 && severance_interest <= 0

      row = Array.new(TOTAL_COLUMNS)

      prefix = extract_prefix
      row[COLUMNS[:worker_code]] = prefix[:code]
      row[COLUMNS[:prefix]] = prefix[:name]
      row[COLUMNS[:consecutive]] = consecutive_num
      row[COLUMNS[:vacation_compensated]] = "FALSE"

      if vacation_value > 0
        row[COLUMNS[:vacation_days]] = 1
        row[COLUMNS[:vacation_payment]] = vacation_value
      end

      if bonus_value > 0
        row[COLUMNS[:bonus_days]] = 30
        row[COLUMNS[:bonus_payment]] = bonus_value
      end

      if severance_value > 0
        row[COLUMNS[:severance_payment]] = severance_value
        row[COLUMNS[:severance_percentage]] = 12
      end

      row[COLUMNS[:severance_interest]] = severance_interest if severance_interest > 0

      row
    end

    def extract_prefix
      code = @period_info[:payroll_prefix] || "NM"
      name = @period_info[:payroll_code] || @period_info[:company_name].to_s.split(/\s+/).first.to_s.upcase
      name = "NOMINA" if name.blank?
      { code: code, name: name }
    end

    def calculate_time_worked(hire_date_str)
      return nil if hire_date_str.blank? || @period_info[:end_date].blank?

      hire = Date.parse(hire_date_str)
      period_end = Date.parse(@period_info[:end_date])
      (period_end - hire).to_i
    rescue
      nil
    end

    def format_number(num, digits = 0)
      return nil if num.nil?
      if digits > 0
        format("%0#{digits}d", num)
      else
        num.to_s
      end
    end
  end
end
