class CreateSurveyResponses < ActiveRecord::Migration[5.1]
  def change
    create_table :survey_responses do |t|
      t.text :text
      t.references :survey_question, foreign_key: true

      t.timestamps
    end
  end
end
