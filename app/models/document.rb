class Document < ApplicationRecord
  SOURCE_FORMATS = %w[syscafe minomina other].freeze
  TARGET_FORMATS = %w[minomina syscafe].freeze

  belongs_to :user

  validates :source_format, presence: true, inclusion: { in: SOURCE_FORMATS }
  validates :target_format, presence: true, inclusion: { in: TARGET_FORMATS }
  validates :file_name, presence: true

  def self.source_format_options
    SOURCE_FORMATS.map { |f| [I18n.t("documents.source_formats.#{f}"), f] }
  end

  def self.target_format_options
    TARGET_FORMATS.map { |f| [I18n.t("documents.target_formats.#{f}"), f] }
  end

  def self.valid_source_format?(format)
    SOURCE_FORMATS.include?(format)
  end

  def self.valid_target_format?(format)
    TARGET_FORMATS.include?(format)
  end
end
