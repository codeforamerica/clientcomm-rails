class CreateHideNotesFeatureFlag < ActiveRecord::Migration[5.1]
  def up
    FeatureFlag.find_or_create_by(flag: 'hide_notes').update!(enabled: false)
  end
end
