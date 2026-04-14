class DocumentsController < ApplicationController
  before_action :authenticate_user!

  def index
    @source_options = Document.source_format_options
    @target_options = Document.target_format_options
    @companies = Company.order(:name)
  end

  def convert
    validate_params!

    uploaded = params[:file]
    parser = Converters::SyscafeParser.new(uploaded.tempfile.path)
    parser.parse

    Rails.logger.info "=== Parse complete, employees found: #{parser.employees.length}"
    Rails.logger.info "=== Period info: #{parser.period_info.inspect}"
    parser.employees.each do |e|
      Rails.logger.info "=== Excel emp: #{e[:document_number]} - #{e[:first_surname]} #{e[:first_name]}"
    end

    # Always use employees from DB, merge with Excel payroll data
    company = Company.find_by(id: params[:company_id])
    employees = build_employees_from_database(parser, params[:company_id])

    if employees.empty?
      redirect_to documents_path, alert: I18n.t("documents.errors.no_employees_found")
      return
    end

    period_info = parser.period_info
    if company
      start_consecutive = company.next_payroll_consecutive(employees.size)
      period_info = period_info.merge(
        payroll_prefix: company.payroll_prefix_or_default,
        payroll_code: company.payroll_code_or_default,
        start_consecutive: start_consecutive
      )
    end

    csv_content = Converters::MinominaCsvGenerator.new(employees, period_info).generate
    filename = "nomina_minomina_#{Time.current.strftime('%Y%m%d_%H%M%S')}.csv"

    send_data csv_content, filename: filename, type: "text/csv", disposition: "attachment"
  rescue DocumentConverterService::InvalidFormatError,
         DocumentConverterService::ConversionError => e
    redirect_to documents_path, alert: e.message
  rescue StandardError => e
    Rails.logger.error("Convert error: #{e.message}\n#{e.backtrace.first(5).join("\n")}")
    redirect_to documents_path, alert: I18n.t("documents.errors.conversion_failed")
  end

  private

  def validate_params!
    unless Document.valid_source_format?(params[:source_format])
      raise DocumentConverterService::InvalidFormatError, I18n.t("documents.errors.invalid_source_format")
    end
    unless Document.valid_target_format?(params[:target_format])
      raise DocumentConverterService::InvalidFormatError, I18n.t("documents.errors.invalid_target_format")
    end
    raise DocumentConverterService::ConversionError, I18n.t("documents.errors.no_file") if params[:file].blank?
  end

  def build_employees_from_database(parser, company_id)
    return parser.employees if company_id.blank?

    company = Company.find_by(id: company_id)
    return parser.employees unless company

    period_start = parser.period_info[:start_date]
    period_end = parser.period_info[:end_date]

    db_employees = company.employees.includes(:contracts).index_by(&:document_number)
    excel_employees = parser.employees.index_by { |e| e[:document_number] }

    Rails.logger.info "=== Company: #{company.name} (ID: #{company_id})"
    Rails.logger.info "=== DB employees: #{db_employees.keys.inspect}"
    Rails.logger.info "=== Excel employees: #{excel_employees.keys.inspect}"
    Rails.logger.info "=== Intersection: #{(db_employees.keys & excel_employees.keys).inspect}"

    db_employees.keys.filter_map do |doc_number|
      excel_emp = excel_employees[doc_number]
      next unless excel_emp

      db_emp = db_employees[doc_number]
      contract = if period_start && period_end
        db_emp.contracts.vigente_en(period_start, period_end)
      else
        db_emp.active_contract || db_emp.latest_contract
      end

      {
        document_number: doc_number,
        document_type: db_emp.document_type,
        first_surname: db_emp.first_surname,
        second_surname: db_emp.second_surname,
        first_name: db_emp.first_name,
        other_names: db_emp.other_names,
        department: db_emp.department,
        municipality: db_emp.municipality,
        address: db_emp.address.presence || excel_emp[:address],
        hire_date: contract&.contract_date&.strftime("%Y-%m-%d"),
        contract_type: contract&.contract_type,
        integral_salary: contract&.integral_salary ? "true" : "false",
        basic_salary: excel_emp[:basic_salary],
        worked_days: excel_emp[:worked_days],
        vacation_days: excel_emp[:vacation_days],
        salary: excel_emp[:salary],
        transport_aid: excel_emp[:transport_aid],
        total_earned: excel_emp[:total_earned],
        loans: excel_emp[:loans],
        health_employee: excel_emp[:health_employee],
        pension_employee: excel_emp[:pension_employee],
        total_deducted: excel_emp[:total_deducted],
        net_pay: excel_emp[:net_pay],
        concepts: excel_emp[:concepts],
        third_parties: excel_emp[:third_parties]
      }
    end
  end
end
