class AddActiveToSurveyResponses < ActiveRecord::Migration[5.1]
  def change
    add_column :survey_responses, :active, :boolean, null: false, default: true
  end
end
