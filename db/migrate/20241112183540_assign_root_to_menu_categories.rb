class AssignRootToMenuCategories < ActiveRecord::Migration[7.0]
  def up
    Menu::Category.all.each do |cat|
      cat.assign_root
      cat.save!
    end
  end

  def down
    Menu::Category.update_all(root_id: nil)
  end
end
