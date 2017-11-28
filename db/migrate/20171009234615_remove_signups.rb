class RemoveSignups < ActiveRecord::Migration[5.1]
  def change
    flag = FeatureFlag.find_by(flag: 'allow_signups')
    flag.destroy if flag.present?
  end
end
