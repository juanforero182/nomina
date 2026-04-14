class ConversionLog < ApplicationRecord
  belongs_to :user
  belongs_to :company

  validates :month, presence: true, inclusion: { in: 1..12 }
  validates :year, presence: true, inclusion: { in: 2020..2030 }

  MONTH_NAMES = %w[Enero Febrero Marzo Abril Mayo Junio Julio Agosto Septiembre Octubre Noviembre Diciembre].freeze

  def month_name
    MONTH_NAMES[month - 1]
  end

  def period_label
    "#{month_name} #{year}"
  end
end
