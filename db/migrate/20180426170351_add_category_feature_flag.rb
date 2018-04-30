class AddCategoryFeatureFlag < ActiveRecord::Migration[5.1]
  def up
    FeatureFlag.create!(
      flag: 'categories',
      enabled: false
    )
  end
end
