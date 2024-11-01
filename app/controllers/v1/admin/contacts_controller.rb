# frozen_string_literal: true

module V1
  module Admin
    # CRUD operations for contacts: key-value objects for contact information.
    class ContactsController < ApplicationController
      # GET /v1/admin/contacts
      def index
        render json: {
          items: Contact.all_list
        }
      end

      # GET /v1/admin/contacts/:key
      def show
        render json: Contact.all_hash[params[:key]]
      end

      # PATCH /v1/admin/contacts/:key
      def save
        @item = Contact.find_or_initialize_by(key: params[:key])
        @item.value = params[:value]
        return render_unprocessable_entity(@item) unless @item.save

        show
      end
    end
  end
end
