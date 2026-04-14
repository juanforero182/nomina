class CreateCompanies < ActiveRecord::Migration[8.1]
  def change
    create_table :companies do |t|
      t.string :name, null: false
      t.string :nit, null: false

      t.timestamps
    end

    add_index :companies, :nit, unique: true
  end
end
