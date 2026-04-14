class MigrateEmployeeDataToContracts < ActiveRecord::Migration[8.1]
  def up
    # Move contract-related data from employees to contracts table
    execute <<-SQL
      INSERT INTO contracts (
        employee_id, contract_date, contract_end_date, contract_type,
        basic_salary, position, area, integral_salary, hire_date,
        health_entity, health_date, pension_entity, pension_date,
        arl_entity, arl_date, compensation_fund, severance_fund,
        vacation_date, bank_name, bank_account, status,
        created_at, updated_at
      )
      SELECT
        id, contract_date, contract_end_date, contract_type,
        basic_salary, position, area, integral_salary, hire_date,
        health_entity, health_date, pension_entity, pension_date,
        arl_entity, arl_date, compensation_fund, severance_fund,
        vacation_date, bank_name, bank_account, status,
        NOW(), NOW()
      FROM employees
      WHERE contract_date IS NOT NULL OR basic_salary IS NOT NULL
    SQL

    # Remove contract-specific columns from employees
    remove_column :employees, :basic_salary
    remove_column :employees, :hire_date
    remove_column :employees, :contract_type
    remove_column :employees, :integral_salary
    remove_column :employees, :position
    remove_column :employees, :health_entity
    remove_column :employees, :health_date
    remove_column :employees, :pension_entity
    remove_column :employees, :pension_date
    remove_column :employees, :arl_entity
    remove_column :employees, :arl_date
    remove_column :employees, :compensation_fund
    remove_column :employees, :severance_fund
    remove_column :employees, :contract_date
    remove_column :employees, :contract_end_date
    remove_column :employees, :vacation_date
    remove_column :employees, :status
    remove_column :employees, :area
    remove_column :employees, :bank_name
    remove_column :employees, :bank_account
  end

  def down
    add_column :employees, :basic_salary, :decimal, precision: 12, scale: 2
    add_column :employees, :hire_date, :date
    add_column :employees, :contract_type, :integer, default: 3, null: false
    add_column :employees, :integral_salary, :boolean, default: false, null: false
    add_column :employees, :position, :string
    add_column :employees, :health_entity, :string
    add_column :employees, :health_date, :date
    add_column :employees, :pension_entity, :string
    add_column :employees, :pension_date, :date
    add_column :employees, :arl_entity, :string
    add_column :employees, :arl_date, :date
    add_column :employees, :compensation_fund, :string
    add_column :employees, :severance_fund, :string
    add_column :employees, :contract_date, :date
    add_column :employees, :contract_end_date, :date
    add_column :employees, :vacation_date, :date
    add_column :employees, :status, :string, default: "active", null: false
    add_column :employees, :area, :string
    add_column :employees, :bank_name, :string
    add_column :employees, :bank_account, :string
  end
end
