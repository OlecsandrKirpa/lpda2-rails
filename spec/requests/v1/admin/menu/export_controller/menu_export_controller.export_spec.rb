# frozen_string_literal: true

require "rails_helper"

RSpec.describe "GET /v1/admin/menu/export" do
  include_context REQUEST_AUTHENTICATION_CONTEXT

  def ingredients
    @ingredients ||= create_list(:menu_ingredient, 5)
  end

  def tags
    @tags ||= create_list(:menu_tag, 5)
  end

  def allergens
    @allergens ||= create_list(:menu_allergen, 5)
  end

  def populate_database
    2.times do
      create(:menu_category).tap do |category|
        category.assign_translation(:name, { it: "it: #{Faker::Lorem.word}", en: "en: #{Faker::Lorem.word}" })
        category.save!

        Random.rand(0..5).times do
          category.dishes << create(:menu_dish).tap do |dish|
            dish.assign_translation(:name, { it: "it: #{Faker::Lorem.word}", en: "en: #{Faker::Lorem.word}" })
            dish.save!

            ingredients.sample(rand(0..3)).each { |ing| dish.ingredients << ing }
            tags.sample(rand(0..3)).each { |tag| dish.tags << tag }
            allergens.sample(rand(0..3)).each { |allergen| dish.allergens << allergen }
          end
        end
      end
    end

    create(:menu_category, status: :deleted)
    create(:menu_dish, status: :deleted)
    create(:menu_allergen, status: :deleted)
    create(:menu_tag, status: :deleted)
    create(:menu_ingredient, status: :deleted)
  end

  let(:file) do
    fname = "/tmp/FOR_TEST_PURPOSES#{SecureRandom.hex}Reservations.xlsx"
    File.write(fname, response.body, mode: "wb")
    Roo::Excelx.new(fname)
  end
  let(:default_headers) { auth_headers }
  let(:default_params) { {} }

  def col_index(sheet_name, col_name)
    file.sheet(sheet_name).row(1).index(col_name) + 1
  end

  def col_values(sheet_name)
    file.sheet(sheet_name).column(col_index(col_name))[1..]
  end

  def req(params: default_params, headers: default_headers)
    get "/v1/admin/menu/export", headers:, params:
  end

  context "when not authenticated" do
    let(:default_headers) { {} }

    before { req }

    it { expect(response).to have_http_status(:unauthorized) }

    it { expect(json).to include(message: String) }
  end

  context "when making basic request" do
    before do
      populate_database
      req
    end

    it { expect(Menu::Category.deleted.count).to be_positive }
    it { expect(Menu::Ingredient.deleted.count).to be_positive }
    it { expect(Menu::Dish.deleted.count).to be_positive }
    it { expect(Menu::Allergen.deleted.count).to be_positive }
    it { expect(Menu::Tag.deleted.count).to be_positive }

    it { expect(Menu::Category.count).to be_positive }
    it { expect(Menu::Ingredient.count).to be_positive }
    it { expect(Menu::Dish.count).to be_positive }
    it { expect(Menu::Tag.count).to be_positive }
    it { expect(Menu::TagsInDish.count).to be_positive }
    it { expect(Menu::DishesInCategory.count).to be_positive }
    it { expect(Menu::Allergen.count).to be_positive }

    it { expect(response).to have_http_status(:ok) }

    it do
      expect(response.headers["Content-Type"]).to eq "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
    end

    it { expect(file.sheets).to match_array(%w[All Allergens Dishes Ingredients Menu Tags]) }

    %w[id name.it name.en description.it description.en status created_at updated_at].each do |col|
      it "Allergens sheet should have column #{col.inspect}" do
        expect(file.sheet("Allergens").row(1)).to include(col)
      end
    end

    %w[id name.it name.en description.it description.en status created_at updated_at].each do |col|
      it "Ingredients sheet should have column #{col.inspect}" do
        expect(file.sheet("Ingredients").row(1)).to include(col)
      end
    end

    %w[id name.it name.en description.it description.en status created_at updated_at].each do |col|
      it "Tags sheet should have column #{col.inspect}" do
        expect(file.sheet("Tags").row(1)).to include(col)
      end
    end

    %w[id name.it name.en description.it description.en status created_at updated_at].each do |col|
      it "Menu sheet should have column #{col.inspect}" do
        expect(file.sheet("Menu").row(1)).to include(col)
      end
    end

    it {
      expect(file.sheet("Allergens").column(col_index("Allergens",
                                                      "id"))).to contain_exactly("id",
                                                                                 *Menu::Allergen.where.not(status: :deleted).map(&:id))
    }

    it {
      expect(file.sheet("Ingredients").column(col_index("Ingredients",
                                                        "id"))).to contain_exactly("id",
                                                                                   *Menu::Ingredient.where.not(status: :deleted).map(&:id))
    }

    it {
      expect(file.sheet("Tags").column(col_index("Tags",
                                                 "id"))).to contain_exactly("id",
                                                                            *Menu::Tag.where.not(status: :deleted).map(&:id))
    }

    it {
      expect(file.sheet("Menu").column(col_index("Menu",
                                                 "id"))).to contain_exactly("id",
                                                                            *Menu::Category.where.not(status: :deleted).without_parent.map(&:id))
    }

    %w[created_at updated_at].each do |col|
      it "checking Dishes sheet #{col.inspect}" do
        expect(file.sheet("Dishes").column(col_index("Dishes",
                                                     col))).to contain_exactly(col, *Menu::Dish.where.not(status: :deleted).map do |t|
                                                                                      t.send(col).strftime("%Y-%m-%d %H:%M")
                                                                                    end)
      end

      it "checking Allergens sheet #{col.inspect}" do
        expect(file.sheet("Allergens").column(col_index("Allergens",
                                                        col))).to contain_exactly(col, *Menu::Allergen.where.not(status: :deleted).map do |t|
                                                                                         t.send(col).strftime("%Y-%m-%d %H:%M")
                                                                                       end)
      end

      it "checking Tags sheet #{col.inspect}" do
        expect(file.sheet("Tags").column(col_index("Tags",
                                                   col))).to contain_exactly(col, *Menu::Tag.where.not(status: :deleted).map do |t|
                                                                                    t.send(col).strftime("%Y-%m-%d %H:%M")
                                                                                  end)
      end

      it "checking Menu sheet #{col.inspect}" do
        expect(file.sheet("Menu").column(col_index("Menu",
                                                   col))).to contain_exactly(col, *Menu::Category.where.not(status: :deleted).where(parent_id: nil).map do |t|
                                                                                    t.send(col).strftime("%Y-%m-%d %H:%M")
                                                                                  end)
      end
    end

    context "when checking dishes" do
      it {
        expect(file.sheet("Dishes").column(col_index("Dishes",
                                                     "id"))).to contain_exactly("id",
                                                                                *Menu::Dish.where.not(status: :deleted).map(&:id))
      }

      it do
        expect(Menu::Dish.visible.count).to be_positive
        row = file.sheet("Dishes").row(2)
        expect(row[col_index("Dishes", "id") - 1]).to be_present
        record = Menu::Dish.find(row[col_index("Dishes", "id") - 1])
        expect(record.name_it).to eq row[col_index("Dishes", "name.it") - 1]
        expect(record.name_en).to eq row[col_index("Dishes", "name.en") - 1]
        expect(record.description_it).to eq row[col_index("Dishes", "description.it") - 1]
        expect(record.description_en).to eq row[col_index("Dishes", "description.en") - 1]
        expect(record.status).to eq row[col_index("Dishes", "status") - 1]
      end
    end
  end
end
