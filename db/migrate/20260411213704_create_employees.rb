class CreateEmployees < ActiveRecord::Migration[8.1]
  def change
    create_table :employees do |t|
      t.references :company, null: false, foreign_key: true
      t.string :document_number, null: false
      t.integer :document_type, default: 13, null: false
      t.string :first_surname, null: false
      t.string :second_surname
      t.string :first_name, null: false
      t.string :other_names
      t.string :position
      t.decimal :basic_salary, precision: 12, scale: 2
      t.date :hire_date
      t.integer :contract_type, default: 3, null: false
      t.integer :department, default: 11, null: false
      t.integer :municipality, default: 11001, null: false
      t.string :address, default: "BOGOTA", null: false
      t.boolean :integral_salary, default: false, null: false

      t.timestamps
    end

    add_index :employees, [:company_id, :document_number], unique: true
  end
end
