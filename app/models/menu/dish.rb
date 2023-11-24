# frozen_string_literal: true

module Menu
  class Dish < ApplicationRecord

    # ##############################
    # Constants, settings, modules, et...
    # ##############################
    extend Mobility
    translates :name
    translates :description

    VALID_STATUSES = %w[active].freeze

    enum status: VALID_STATUSES.map{ |s| [s, s] }.to_h

    # ##############################
    # Associations
    # ##############################
    has_many :menu_dishes_in_categories, class_name: 'Menu::DishesInCategory', foreign_key: :menu_dish_id, dependent: :destroy
    has_many :menu_categories, class_name: 'Menu::Category', through: :menu_dishes_in_categories
    has_many :menu_ingredients_in_dishes, class_name: 'Menu::IngredientsInDish', foreign_key: :menu_dish_id, dependent: :destroy
    has_many :menu_ingredients, class_name: 'Menu::Ingredient', through: :menu_ingredients_in_dishes
    has_many :menu_allergens_in_dishes, class_name: 'Menu::AllergensInDish', foreign_key: :menu_dish_id, dependent: :destroy
    has_many :menu_allergens, class_name: 'Menu::Allergen', through: :menu_allergens_in_dishes
    has_many :menu_tags_in_dishes, class_name: 'Menu::TagsInDish', :foreign_key => :menu_dish_id, dependent: :destroy
    has_many :menu_tags, class_name: 'Menu::Tag', through: :menu_tags_in_dishes

    alias_attribute :categories, :menu_categories
    alias_attribute :ingredients, :menu_ingredients
    alias_attribute :allergens, :menu_allergens
    alias_attribute :tags, :menu_tags

    # ##############################
    # Validators
    # ##############################
    validates :price, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
    validates :status, presence: true, inclusion: { in: VALID_STATUSES }

    # ##############################
    # Hooks
    # ##############################
    before_validation :assign_defaults, on: :create

    # ##############################
    # Instance methods
    # ##############################
    def status=(value)
      super
    rescue ArgumentError
      @attributes.write_cast_value("status", value)
    end

    def assign_defaults
      self.status = 'active' if status.blank?
      self.other = {} if other.nil?
    end
  end
end
