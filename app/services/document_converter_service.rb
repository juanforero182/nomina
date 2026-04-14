class DocumentConverterService
  class InvalidFormatError < StandardError; end
  class ConversionError < StandardError; end

  attr_reader :source_format, :target_format, :file

  def initialize(source_format:, target_format:, file:)
    @source_format = source_format
    @target_format = target_format
    @file = file
  end

  def call
    validate_formats!
    validate_file!
    convert
  end

  private

  def validate_formats!
    unless Document.valid_source_format?(source_format)
      raise InvalidFormatError, I18n.t("documents.errors.invalid_source_format")
    end

    unless Document.valid_target_format?(target_format)
      raise InvalidFormatError, I18n.t("documents.errors.invalid_target_format")
    end
  end

  def validate_file!
    raise ConversionError, I18n.t("documents.errors.no_file") if file.blank?
  end

  def convert
    case [source_format, target_format]
    when %w[syscafe minomina]
      convert_syscafe_to_minomina
    else
      raise InvalidFormatError, I18n.t("documents.errors.unsupported_conversion")
    end
  end

  def convert_syscafe_to_minomina
    parser = Converters::SyscafeParser.new(file.tempfile.path)
    parser.parse

    if parser.employees.empty?
      raise ConversionError, I18n.t("documents.errors.no_employees_found")
    end

    csv_content = Converters::MinominaCsvGenerator.new(
      parser.employees,
      parser.period_info
    ).generate

    {
      success: true,
      csv_content: csv_content,
      filename: generate_filename,
      employees_count: parser.employees.length
    }
  end

  def generate_filename
    timestamp = Time.current.strftime("%Y%m%d_%H%M%S")
    "nomina_minomina_#{timestamp}.csv"
  end
end
