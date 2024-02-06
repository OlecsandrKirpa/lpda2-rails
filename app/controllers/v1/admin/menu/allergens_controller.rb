# frozen_string_literal: true

module V1::Admin::Menu
  class AllergensController < ApplicationController
    before_action :find_item, only: %i[show update destroy]

    def index
      call = ::Menu::SearchAllergens.run(params:, current_user:)
      return render_error(status: 400, details: call.errors.as_json, message: call.errors.full_messages.join(', ')) unless call.valid?

      items = call.result.paginate(pagination_params)

      render json: {
        items: full_json(items),
        metadata: json_metadata(items)
      }
    end

    def show
      render json: {
        item: full_json(@item)
      }
    end

    def create
      @item = Menu::Allergen.new
      @item.assign_translation('name', params[:name]) if params[:name].present?
      @item.assign_translation('description', params[:description]) if params[:description].present?

      return show if @item.errors.empty? && @item.valid? && @item.save

      render_unprocessable_entity(@item)
    end

    def update
      @item.assign_translation('name', params[:name]) if params.key?(:name)
      @item.assign_translation('description', params[:description]) if params.key?(:description)

      return show if @item.errors.empty? && @item.valid? && @item.save

      render_unprocessable_entity(@item)
    end

    def destroy
      return if @item.deleted!

      render_unprocessable_entity(@item)
    rescue ActiveRecord::RecordInvalid
      render_unprocessable_entity(@item)
    end

    private

    def find_item
      @item = Menu::Allergen.visible.where(id: params[:id]).first
      render_error(status: 404, message: I18n.t('record_not_found', model: Menu::Allergen, id: params[:id].inspect)) if @item.nil?
    end

    def full_json(item_or_items)
      return item_or_items.map { |item| full_json(item) } if item_or_items.is_a?(ActiveRecord::Relation)

      return single_item_full_json(item_or_items) if item_or_items.is_a?(::Menu::Allergen)

      raise ArgumentError, "Invalid params. Menu::Allergen or ActiveRecord::Relation expected, but #{item_or_items.class} given"
    end

    def single_item_full_json(item)
      item.as_json.merge(
        name: item.name,
        description: item.description,
        image: item.image&.full_json
      )
    end
  end
end
