# frozen_string_literal: true

require "rails_helper"

RSpec.describe Menu::Category, type: :model do
  include_context TESTS_OPTIMIZATIONS_CONTEXT

  context "can be translated" do
    subject { create(:menu_category) }

    include_examples MODEL_MOBILITY_EXAMPLES, field: :name
    include_examples MODEL_MOBILITY_EXAMPLES, field: :description
  end

  context "should track changes with ModelChange" do
    let(:record) { create(:menu_category) }

    include_examples TEST_MODEL_CHANGE_INCLUSION
  end

  context "has image" do
    subject { create(:menu_category) }

    include_examples HAS_IMAGES_HELPER
  end

  def valid_statuses
    Menu::Category::VALID_STATUSES
  end

  def min_secret_length
    Menu::Category::SECRET_MIN_LENGTH
  end

  context "should have valid factories" do
    subject { build(:menu_category) }

    it { is_expected.to be_valid }
    it { expect { subject.save! }.not_to raise_error }
  end

  context "validations" do
    context "basic" do
      subject { build(:menu_category) }

      before { allow_any_instance_of(Menu::Category).to receive(:assign_defaults).and_return(true) }

      it { is_expected.to be_valid }

      it { is_expected.to validate_presence_of(:status) }
      it { is_expected.to validate_inclusion_of(:status).in_array(valid_statuses) }
      it { is_expected.not_to allow_value(nil).for(:status) }
      it { is_expected.not_to allow_value("some_invalid_status").for(:status) }

      it { is_expected.to validate_presence_of(:secret) }
      it { is_expected.not_to allow_value(nil).for(:secret) }
      it { is_expected.not_to allow_value("a").for(:secret) }
      it { is_expected.to allow_value("a" * min_secret_length).for(:secret) }
      it { is_expected.to validate_uniqueness_of(:secret).case_insensitive }

      it { is_expected.to allow_value(nil).for(:secret_desc) }
      it { is_expected.to validate_uniqueness_of(:secret_desc).case_insensitive.allow_nil }

      it { is_expected.not_to allow_value(nil).for(:other) }

      it { is_expected.to allow_value(nil).for(:price) }
      it { is_expected.to allow_value(0).for(:price) }
      it { is_expected.to allow_value(10).for(:price) }
      it { is_expected.to allow_value(100).for(:price) }
      it { is_expected.not_to allow_value(-1).for(:price) }
      it { is_expected.not_to allow_value(-10).for(:price) }

      context "index" do
        before { described_class.destroy_all }

        it { is_expected.to allow_value(nil).for(:index) }
        it { is_expected.to allow_value(0).for(:index) }
        it { is_expected.to allow_value(10).for(:index) }
        it { is_expected.to allow_value(100).for(:index) }

        context "two element with same index but different parent_id may exist." do
          let!(:parent) { create(:menu_category, index: 0) }
          let!(:child) { create(:menu_category, parent:, index: 0, visibility: nil) }

          context "checking mock data" do
            it { expect(parent.reload.index).to eq 0 }
            it { expect(child.reload.index).to eq 0 }
          end

          it { expect(parent).to be_valid }
          it { expect(parent).to be_persisted }
          it { expect(child).to be_valid }
          it { expect(child).to be_persisted }
          it { expect(child.index).to eq parent.index }
          it { expect(child.parent_id).to eq parent.id }
          it { expect(described_class.count).to eq 2 }

          it do
            expect { child.remove_parent! }.not_to raise_error
            expect(child.reload.parent_id).to be_nil
            expect(child.reload.index).to eq 1
            expect(parent.reload.index).to eq 0
          end
        end
      end

      context "parent_id cannot be self" do
        subject { category }

        let(:category) { create(:menu_category) }

        it { is_expected.to be_valid }
        it { is_expected.to be_persisted }

        context "when saving" do
          before { subject.parent_id = subject.id }

          it { is_expected.not_to be_valid }
          it { expect(subject.save).to eq false }
          it { expect { subject.save! }.to raise_error(ActiveRecord::RecordInvalid) }
        end
      end
    end

    %i[secret secret_desc].each do |field|
      context "#{field} should be a string that can be put in a link" do
        subject { build(:menu_category) }

        it { is_expected.to allow_value("a" * min_secret_length).for(field) }
        it { is_expected.to allow_value("bananagang123123123").for(field) }
        it { is_expected.to allow_value("ba-na-na-gang-123-321").for(field) }
        it { is_expected.to allow_value("MenuInterattivo").for(field) }
        it { is_expected.to allow_value("MenuInterattivo-").for(field) }
        it { is_expected.to allow_value("MenuInterattivo_").for(field) }

        it { is_expected.not_to allow_value("MenuInterattivo,").for(field) }
        it { is_expected.not_to allow_value("MenuInterattivo.").for(field) }
        it { is_expected.not_to allow_value("MenuInterattivo;").for(field) }
        it { is_expected.not_to allow_value("MenuInterattivo:").for(field) }
        it { is_expected.not_to allow_value("banana gang").for(field) }
        it { is_expected.not_to allow_value("bananagang!").for(field) }
        it { is_expected.not_to allow_value("bananagang%").for(field) }
        it { is_expected.not_to allow_value("bananagang&").for(field) }
        it { is_expected.not_to allow_value("bananagang/").for(field) }
        it { is_expected.not_to allow_value("bananagang$").for(field) }
        it { is_expected.not_to allow_value("bananagang£").for(field) }
        it { is_expected.not_to allow_value('bananagang"').for(field) }
        it { is_expected.not_to allow_value("bananagang|").for(field) }
        it { is_expected.not_to allow_value("bananagang'").for(field) }
        it { is_expected.not_to allow_value("bananagang^").for(field) }
        it { is_expected.not_to allow_value("bananagang]").for(field) }
        it { is_expected.not_to allow_value("bananagang[").for(field) }
        it { is_expected.not_to allow_value("bananagang#").for(field) }
        it { is_expected.not_to allow_value("bananagang*").for(field) }
        it { is_expected.not_to allow_value("bananagang+").for(field) }
        it { is_expected.not_to allow_value("bananagang}").for(field) }
        it { is_expected.not_to allow_value("bananagang{").for(field) }
        it { is_expected.not_to allow_value("bananagang°s").for(field) }
      end
    end

    context "should not be able to create two elements with same secret" do
      subject { described_class.new(original.as_json(except: [:id, "id"])) }

      let(:original) { create(:menu_category) }

      it { expect(original).to be_valid }
      it { expect(original).to be_persisted }

      it { expect(subject).not_to be_valid }
      it { expect(subject).not_to be_persisted }
      it { expect(subject.validate).to be false }
      it { expect { subject.save! }.to raise_error(ActiveRecord::RecordInvalid) }

      it "has errors in :secret field" do
        subject.validate
        expect(subject.errors[:secret]).to be_a(Array)
        expect(subject.errors[:secret].count).to be > 0
      end
    end

    context "should not be able to create two elements with same secret_desc" do
      subject { described_class.new(original.as_json(except: [:id, "id"])) }

      let(:original) { create(:menu_category, secret_desc: "secret-#{SecureRandom.hex(20)}") }

      it { expect(original).to be_valid }
      it { expect(original).to be_persisted }

      it { expect(subject).not_to be_valid }
      it { expect(subject).not_to be_persisted }
      it { expect(subject.validate).to be false }
      it { expect { subject.save! }.to raise_error(ActiveRecord::RecordInvalid) }

      it "has errors in :secret_desc field" do
        subject.validate
        expect(subject.errors[:secret_desc]).to be_a(Array)
        expect(subject.errors[:secret_desc].count).to be > 0
      end
    end
  end

  context "associations" do
    before { allow_any_instance_of(Menu::Category).to receive(:assign_defaults).and_return(true) }

    it { is_expected.to belong_to(:menu_visibility).optional.dependent(:destroy) }

    context "when deleted, should destroy all DishInCategory" do
      subject { category }

      let(:dish) { create(:menu_dish) }
      let(:category) { create(:menu_category) }
      let!(:dish_in_category) { create(:menu_dishes_in_category, menu_dish: dish, menu_category: category) }

      it { is_expected.to be_valid }
      it { is_expected.to be_persisted }
      it { expect(dish.categories).to include(category) }
      it { expect(category.dishes).to include(dish) }
      it { expect(dish.categories.count).to eq 1 }
      it { expect(category.dishes.count).to eq 1 }
      it { expect { category.destroy! }.to change { Menu::DishesInCategory.count }.by(-1) }
      it { expect { category.destroy! }.to change { Menu::Visibility.count }.by(-1) }
      it { expect { category.destroy! }.not_to(change { Menu::Dish.count }) }
    end

    context 'when trying to delete a "parent" category, should raise some error.' do
      subject { parent }

      let(:parent) do
        create(:menu_category, visibility: nil, parent: create(:menu_category)).parent
      end

      it { is_expected.to be_valid }
      it { is_expected.to be_persisted }
      it { is_expected.to have_children }

      it "does not allow do destroy a parent." do
        expect { parent.destroy! }.to raise_error(ActiveRecord::RecordNotDestroyed)
      end

      it "is able to destroy element if remove all children first." do
        parent.children.map { |c| c.update!(parent: nil) }
        expect { parent.destroy! }.not_to raise_error
      end
    end

    context "when has parent" do
      subject { build(:menu_category, visibility: nil, parent: build(:menu_category)) }

      it { is_expected.to be_valid }
      it { expect(subject.save!).to be true }
      it { expect { subject.save! }.not_to raise_error }
    end

    context "when hasn't parent" do
      subject { build(:menu_category, parent: nil) }

      it { is_expected.to be_valid }
      it { expect(subject.save!).to be true }
      it { expect { subject.save! }.not_to raise_error }
    end

    context 'adding dishes with "="' do
      subject { create(:menu_category) }

      let(:dishes) { create_list(:menu_dish, 2) }

      it { is_expected.to be_valid }
      it { is_expected.to be_persisted }
      it { expect(subject.dishes.count).to eq 0 }

      it "dishes should not have any category" do
        expect(dishes.map(&:categories).flatten.count).to eq 0
      end

      it "works" do
        expect { subject.dishes = dishes }.not_to raise_error
        expect(subject.reload.dishes.count).to eq 2
        expect(subject.dishes.map(&:id)).to match_array(dishes.map(&:id))
        dishes.map(&:reload)
        expect(dishes.map(&:categories).flatten.map(&:id).uniq).to eq [subject.id]
      end
    end

    context "when adding visibility to a non-root category should raise error" do
      subject { create(:menu_category, parent:, menu_visibility: nil) }

      let(:parent) { create(:menu_category) }
      let(:visibility) { create(:menu_visibility) }

      it { expect(subject).to be_valid }
      it { expect(subject).to be_persisted }
      it { expect(subject.parent).to eq parent }
      it { expect(subject.menu_visibility).to be_nil }
      it { expect(subject.visibility).to be_nil }
      it { expect(parent.visibility).not_to be_nil }
      it { expect(parent.visibility).to be_a(Menu::Visibility) }

      it "raises error" do
        expect { subject.update!(menu_visibility: visibility) }.to raise_error(ActiveRecord::RecordInvalid)
      end

      it "is not valid" do
        subject.menu_visibility = visibility
        expect(subject).to be_invalid
        expect(subject.errors[:visibility]).to be_present
      end
    end

    context 'adding dishes with "<<"' do
      subject { create(:menu_category).tap { |cat| cat.dishes = create_list(:menu_dish, 2) } }

      let(:dish) { build(:menu_dish) }

      it { is_expected.to be_valid }
      it { is_expected.to be_persisted }
      it { expect(subject.dishes.count).to eq 2 }

      it "works" do
        expect { subject.dishes << dish }.not_to raise_error
        expect(subject.reload.dishes.count).to eq 3
        expect(dish.categories.map(&:id).uniq).to eq [subject.id]
      end
    end
  end

  context "instance methods" do
    subject { build(:menu_category) }

    it { is_expected.to respond_to(:menu_visibility) }
    it { is_expected.to respond_to(:menu_visibility=) }
    it { is_expected.to respond_to(:visibility) }
    it { is_expected.to respond_to(:visibility=) }
    it { is_expected.to respond_to(:menu_visibility_id) }
    it { is_expected.to respond_to(:menu_visibility_id=) }
    it { is_expected.to respond_to(:visibility_id) }
    it { is_expected.to respond_to(:visibility_id=) }
    it { is_expected.to respond_to(:menu_dishes) }
    it { is_expected.to respond_to(:menu_dishes=) }
    it { is_expected.to respond_to(:dishes) }
    it { is_expected.to respond_to(:dishes=) }
    it { is_expected.to respond_to(:menu_dishes_in_categories) }
    it { is_expected.to respond_to(:menu_dishes_in_categories=) }

    describe "#visibility should alias to menu_visibility" do
      subject { create(:menu_category) }

      it { is_expected.to respond_to(:visibility) }
      it { is_expected.to respond_to(:menu_visibility) }
      it { expect(subject.visibility).to eq subject.menu_visibility }
    end

    describe "#filter_by_query should return all if is blank" do
      subject(:result) { described_class.filter_by_query([nil, ""].sample) }

      let(:categories) { create_list(:menu_category, 3) }

      before { categories }

      it { is_expected.to be_a(ActiveRecord::Relation) }
      it { expect(result.count).to eq 3 }
    end
  end

  context "should define methods since valid statuses" do
    subject { build(:menu_category) }

    it { is_expected.to respond_to(:active!) }
    it { is_expected.to respond_to(:active?) }

    it { expect(described_class).to respond_to(:active) }
  end

  context "scopes" do
    describe ".with_fixed_price and .without_fixed_price" do
      let!(:with_price) { create_list(:menu_category, 2, price: 5.2) }
      let!(:without_price) { create_list(:menu_category, 2, price: nil) }

      it { expect(described_class.count).to eq 4 }
      it { expect(described_class.with_fixed_price.count).to eq 2 }
      it { expect(described_class.without_fixed_price.count).to eq 2 }
      it { expect(described_class.without_fixed_price.map(&:price)).to all(eq nil) }
      it { expect(described_class.with_fixed_price.map(&:price)).to all(be_a(Numeric)) }
      it { expect(described_class.with_fixed_price.map(&:price)).to all(be_positive) }

      it { expect(described_class.without_price.map(&:price)).to all(eq nil) }
      it { expect(described_class.with_price.map(&:price)).to all(be_positive) }
    end
  end
end
