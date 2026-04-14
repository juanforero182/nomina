class AddPayrollFieldsToCompanies < ActiveRecord::Migration[8.1]
  def change
    add_column :companies, :payroll_prefix, :string, default: "NM"
    add_column :companies, :payroll_code, :string
    add_column :companies, :last_payroll_consecutive, :integer, default: 0, null: false
  end
end
