# frozen_string_literal: true

module Sheet
  module Eeds
    class ExcelImport < Base
      self.parent_sheet = Sheet::Group

      def title
        I18n.t("eeds.excel_imports.title", default: "Import Excel")
      end
    end
  end
end
