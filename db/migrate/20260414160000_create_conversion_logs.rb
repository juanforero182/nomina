class CreateConversionLogs < ActiveRecord::Migration[8.1]
  def change
    create_table :conversion_logs do |t|
      t.references :user, null: false, foreign_key: true
      t.references :company, null: false, foreign_key: true
      t.integer :month, null: false
      t.integer :year, null: false
      t.string :syscafe_file_name
      t.string :provisions_file_name
      t.timestamps
    end
  end
end
