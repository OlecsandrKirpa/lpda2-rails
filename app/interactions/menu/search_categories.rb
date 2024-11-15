# frozen_string_literal: true

module Menu
  class SearchCategories < SearchRecords
    interface :all, methods: %i[visible without_parent], default: -> { Category.all }

    def execute
      categories = all.visible

      categories = categories.without_parent.public_visible if param_true?(:root, :without_parent, :root_only)

      if params[:except].present? && params[:except].is_a?(String)
        categories = categories.where.not(id: params[:except].split(",").map(&:to_i))
      end

      categories = categories.where(parent_id: params[:parent_id].presence) if params.has_key?(:parent_id)

      if params[:query].present? && params[:query].is_a?(String)
        categories = categories.where(id: Category.filter_by_query(params[:query]).select(:id))
      end

      if params[:fixed_price].present?
        value = params[:fixed_price].to_s.downcase == "true"
        categories = value ? categories.with_fixed_price : categories.without_fixed_price
      end

      categories.order(:index)
    end
  end
end
