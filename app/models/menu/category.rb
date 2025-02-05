# frozen_string_literal: true

module Menu
  class Category < ApplicationRecord
    # ##############################
    # Constants, modules
    # ##############################
    include TrackModelChanges
    include HasImagesAttached
    extend Mobility
    translates :name
    translates :description

    VALID_STATUSES = %w[active deleted].freeze
    SECRET_MIN_LENGTH = 8

    enum status: VALID_STATUSES.map { |s| [s, s] }.to_h

    # ##############################
    # Associations
    # ##############################
    belongs_to :menu_visibility, dependent: :destroy, class_name: "Menu::Visibility", optional: true
    alias_attribute :visibility_id, :menu_visibility_id
    alias_attribute :visibility, :menu_visibility

    belongs_to :parent, class_name: "Menu::Category", optional: true
    belongs_to :root, class_name: "Menu::Category", optional: true
    has_many :children, class_name: "Menu::Category", foreign_key: :parent_id # , dependent: :destroy

    has_many :menu_dishes_in_categories, class_name: "Menu::DishesInCategory", foreign_key: :menu_category_id

    has_many :menu_dishes, through: :menu_dishes_in_categories, class_name: "Menu::Dish", dependent: :destroy,
                           after_remove: :after_remove_dish
    alias_attribute :dishes, :menu_dishes

    # ##############################
    # Validations
    # ##############################
    validates :status, presence: true, inclusion: { in: VALID_STATUSES }
    validates :secret, presence: true, length: { minimum: SECRET_MIN_LENGTH }, uniqueness: { case_sensitive: false },
                       format: { multiline: true, with: /^[a-zA-Z0-9_-]+$/ }
    validates :secret_desc, uniqueness: { case_sensitive: false }, allow_nil: true,
                            format: { multiline: true, with: /^[a-zA-Z0-9_-]+$/ }
    validates :price, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
    validates :index, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true, uniqueness: { scope: :parent_id }
    validate :other_cannot_be_nil
    validate :parent_id_cannot_be_self
    validate :visibility_must_be_nil_unless_root
    validate :visibility_must_be_present_if_root

    # ##############################
    # Hooks
    # ##############################
    # after_initialize :assign_valid_index, if: -> { new_record? }
    before_validation :assign_defaults, on: :create
    before_validation :assign_valid_index
    before_validation :assign_default_visibility_if_necessary
    before_validation :assign_root
    before_destroy :check_if_has_children

    # ##############################
    # Scopes
    # ##############################
    scope :visible, -> { where(status: %w[active]) }
    scope :with_fixed_price, -> { where.not(price: nil) }
    scope :with_price, -> { with_fixed_price }
    scope :without_fixed_price, -> { where(price: nil) }
    scope :without_price, -> { without_fixed_price }
    scope :with_parent, -> { where.not(parent_id: nil) }
    scope :without_parent, -> { where(parent_id: nil) }
    scope :root, -> { without_parent }
    scope :public_visible, lambda {
      ids = joins("JOIN menu_visibilities v ON v.id = menu_categories.menu_visibility_id")
            .where(<<~SQL.squish, time: Time.zone.now).select("menu_categories.id")
              v.public_visible = true AND
              (v.daily_from IS NULL OR v.daily_from < :time) AND
              (v.daily_to IS NULL OR v.daily_to > :time) AND
              (v.public_from IS NULL OR v.public_from <= :time) AND
              (v.public_to IS NULL OR v.public_to >= :time)
            SQL

      where(id: ids).or(where(root_id: ids))
    }

    scope :private_visible, lambda {
      ids = joins("JOIN menu_visibilities v ON v.id = menu_categories.menu_visibility_id")
            .where(<<~SQL.squish, time: Time.zone.now).select("menu_categories.id")
              v.private_visible = true AND
              (v.private_from IS NULL OR v.private_from <= :time) AND
              (v.private_to IS NULL OR v.private_to >= :time)
            SQL

      where(id: ids).or(where(root_id: ids))
    }

    # scope :having_dishes, -> { joins(:menu_dishes).distinct }
    scope :having_public_dishes, lambda {
      where(
        id: Menu::DishesInCategory.select(:menu_category_id).where(
          menu_dish_id: Menu::Dish.visible.public_visible.select(:id)
        )
      )
    }

    scope :having_children, -> { where(id: Category.select(:parent_id)) }

    scope :public_or_private_visible, -> { public_visible.or(private_visible) }

    # ##############################
    # Class methods
    # ##############################
    class << self
      def filter_by_query(query)
        return all unless query.present?

        where(id: ransack(name_cont: query).result.select(:id)).or(where(id: ransack(description_cont: query).result.select(:id)))
      end
    end

    # ##############################
    # Instance methods
    # ##############################
    def after_remove_dish(_dish)
      Menu::Dish.adjust_indexes_for_category(id)
    end

    def assign_defaults
      self.status = "active" if status.blank?
      # assign_valid_index if index.to_i.zero?
      self.secret = GenToken.for!(self.class, :secret) if secret.blank?
      self.other = {} if other.nil?
    end

    # @param [Hash] options
    # @option options [User] :current_user
    def copy!(options = {})
      CopyCategory.run!(params: options.merge(old: self))
    end

    # @param [Hash] options
    # @option options [User] :current_user
    def copy(options = {})
      CopyCategory.run(params: options.merge(old: self))
    end

    def assign_default_visibility_if_necessary
      assign_default_visibility if visibility.nil? && visibility_id.nil? && parent.nil? && parent_id.nil?
    end

    def public_visible?
      visibility&.public_visible?
    end

    def public_visible!
      visibility&.public_visible!
    end

    def private_visible?
      visibility&.private_visible?
    end

    def private_visible!
      visibility&.private_visible!
    end

    def price?
      price.present?
    end

    def assign_valid_index
      self.index = Category.where(parent_id:).count

      return unless Category.where(parent_id:, index:).present?

      self.index = Category.where(parent_id:).order(index: :desc).first&.index.to_i + 1
    end

    def remove_parent!
      update!(parent: nil)
    end

    def can_publish?
      CanPublishCategory.run(category: self).result
    end

    def has_children?
      children.count.positive?
    end

    def status=(value)
      super
    rescue ArgumentError
      @attributes.write_cast_value("status", value)
    end

    def move(to_index)
      return true if index == to_index

      to_index = self.class.where(parent_id:).count - 1 if to_index >= self.class.where(parent_id:).count

      transaction do
        self.class.lock

        self.class.where(parent_id:).update_all("index = index + 100000")

        items = self.class.where(parent_id:).order(:index).to_ary

        items.filter { |t| t.id != id }.each_with_index do |image_to_record, index|
          image_to_record.index = to_index > index ? index : index + 1
        end

        items.find { |it| it.id == id }.index = to_index

        self.class.import items, on_duplicate_key_update: { columns: %i[index] }, validate: false, touch: true
      end

      reload

      valid?
    end

    def breadcrumbs_json
      breadcrumb = [self]
      parent = self.parent
      while parent
        breadcrumb << parent
        parent = parent.parent
      end

      breadcrumb.reverse!
      breadcrumb.map { |item| item.as_json(only: %i[id]).merge(name: item.name) }
    end

    def assign_root
      self.root = nil
      return if parent.nil?

      root = parent
      root = root.parent while root.parent.present?

      self.root = root
    end

    private

    def assign_default_visibility
      self.visibility ||= Menu::Visibility.new
    end

    def visibility_must_be_nil_unless_root
      return if parent.nil? && parent_id.nil?
      return if visibility.nil? && visibility_id.nil?

      errors.add(:visibility, "must be nil unless root category")
    end

    def visibility_must_be_present_if_root
      return if visibility_id.present? || visibility.present?
      return if parent.present? || parent_id.present?

      errors.add(:visibility, "must be present if root category")
    end

    def other_cannot_be_nil
      return unless other.nil?

      errors.add(:other, "can't be nil")
    end

    def parent_id_cannot_be_self
      return if id.nil? || parent_id.nil?
      return unless parent_id == id

      errors.add(:parent_id, "can't be self")
    end

    def check_if_has_children
      return unless has_children?

      errors.add(:base, "can't delete category with children")
      throw :abort
    end
  end
end
