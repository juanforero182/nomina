class CreateContracts < ActiveRecord::Migration[8.1]
  def change
    create_table :contracts do |t|
      t.references :employee, null: false, foreign_key: true
      t.string :contract_number
      t.date :contract_date
      t.date :contract_end_date
      t.integer :contract_type, default: 3, null: false
      t.decimal :basic_salary, precision: 12, scale: 2
      t.string :position
      t.string :area
      t.boolean :integral_salary, default: false, null: false
      t.date :hire_date
      t.string :health_entity
      t.date :health_date
      t.string :pension_entity
      t.date :pension_date
      t.string :arl_entity
      t.date :arl_date
      t.string :compensation_fund
      t.string :severance_fund
      t.date :vacation_date
      t.string :bank_name
      t.string :bank_account
      t.string :status, default: "active", null: false

      t.timestamps
    end

    add_index :contracts, [:employee_id, :contract_number], unique: true
  end
end
