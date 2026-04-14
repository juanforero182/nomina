class Employee < ApplicationRecord
  belongs_to :company
  has_many :contracts, dependent: :destroy

  DOCUMENT_TYPES = {
    11 => "RC",    # Registro civil
    12 => "TI",    # Tarjeta de identidad
    13 => "CC",    # Cedula de ciudadania
    21 => "TE",    # Tarjeta de extranjeria
    22 => "CE",    # Cedula de extranjeria
    31 => "NIT",   # NIT
    41 => "PAS",   # Pasaporte
    42 => "DIE"    # Documento de identificacion extranjero
  }.freeze

  validates :document_number, presence: true, uniqueness: { scope: :company_id }
  validates :document_type, presence: true, inclusion: { in: DOCUMENT_TYPES.keys }
  validates :first_surname, presence: true
  validates :first_name, presence: true

  def full_name
    [first_surname, second_surname, first_name, other_names].compact_blank.join(" ")
  end

  def document_type_label
    DOCUMENT_TYPES[document_type] || document_type.to_s
  end

  def latest_contract
    contracts.latest.first
  end

  def active_contract
    contracts.active.latest.first
  end
end
