# frozen_string_literal: true

module V1
  module Admin::Menu
    class IngredientsController < ApplicationController
      before_action :find_item, only: %i[show update destroy copy]

      def index
        call = ::Menu::SearchIngredients.run(params:)
        unless call.valid?
          return render_error(status: 400, details: call.errors.as_json,
                              message: call.errors.full_messages.join(", "))
        end

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
        @item = ::Menu::Ingredient.new
        @item.assign_translation("name", params[:name]) if params.key?(:name)
        @item.assign_translation("description", params[:description]) if params.key?(:description)

        if params[:image].is_a?(ActionDispatch::Http::UploadedFile)
          @item.image = Image.create_from_param!(params[:image])
        end

        return show if @item.valid? && @item.save

        render_error(status: 400, details: @item.errors.as_json, message: @item.errors.full_messages.join(", "))
      end

      def update
        @item.assign_translation("name", params[:name]) if params.key?(:name)
        @item.assign_translation("description", params[:description]) if params.key?(:description)

        return if params.key?(:image) && !assign_image_from_param(@item, params[:image])

        return show if @item.valid? && @item.save

        render_error(status: 400, details: @item.errors.as_json, message: @item.errors.full_messages.join(", "))
      end

      def destroy
        return if @item.deleted!

        render_unprocessable_entity(@item)
      rescue ActiveRecord::RecordInvalid
        render_unprocessable_entity(@item)
      end

      def copy
        call = ::Menu::CopyIngredient.run(
          old: @item,
          current_user:,
          copy_image: params[:copy_image]
        )

        if call.valid?
          @item = call.result
          return show
        end

        render_error(status: 422, message: call.errors.full_messages.join(", "), details: call.errors.full_json)
      end

      private

      def full_json(item_or_items)
        if item_or_items.is_a?(ActiveRecord::Relation)
          return item_or_items.includes(:text_translations, image: :attached_image_blob).map { |item| full_json(item) }
        end

        return single_item_full_json(item_or_items) if item_or_items.is_a?(::Menu::Ingredient)

        raise ArgumentError,
              "Invalid params.::Menu::Ingredient or ActiveRecord::Relation expected, but #{item_or_items.class} given"
      end

      def single_item_full_json(item)
        item.as_json.merge(
          name: item.name,
          description: item.description,
          image: item.image&.full_json,
          translations: item.translations_json
        )
      end

      def find_item
        @item = ::Menu::Ingredient.visible.find_by(id: params[:id])
        return unless @item.nil?

        render_error(status: 404,
                     message: I18n.t("record_not_found", model: ::Menu::Ingredient,
                                                         id: params[:id].inspect))
      end
    end
  end
end
