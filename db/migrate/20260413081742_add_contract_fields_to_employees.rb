class AddContractFieldsToEmployees < ActiveRecord::Migration[8.1]
  def change
    add_column :employees, :phone, :string
    add_column :employees, :mobile, :string
    add_column :employees, :gender, :string
    add_column :employees, :email, :string
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
