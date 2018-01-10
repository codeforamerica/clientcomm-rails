class CreateSurveyResponseLinks < ActiveRecord::Migration[5.1]
  def change
    create_table :survey_response_links do |t|
      t.references :survey, foreign_key: true
      t.references :survey_response, foreign_key: true

      t.timestamps
    end
  end
end
