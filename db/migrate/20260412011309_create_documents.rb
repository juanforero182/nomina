class CreateDocuments < ActiveRecord::Migration[8.1]
  def change
    create_table :documents do |t|
      t.string :source_format, null: false
      t.string :target_format, null: false
      t.string :file_name, null: false
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
  end
end
