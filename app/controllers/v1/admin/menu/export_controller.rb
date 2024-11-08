# frozen_string_literal: true

module V1::Admin::Menu
  # Export menu utils
  class ExportController < ApplicationController
    # GET /v1/admin/menu/export
    def export
      @file = ::Menu::ExportMenu.run!

      send_file @file, filename: "menu.xlsx", type: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
    end
  end
end
