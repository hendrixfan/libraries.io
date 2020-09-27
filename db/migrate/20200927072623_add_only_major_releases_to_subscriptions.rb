class AddOnlyMajorReleasesToSubscriptions < ActiveRecord::Migration[5.2]
  def change
    add_column :subscriptions, :only_major_releases, :boolean, default: false
  end
end
