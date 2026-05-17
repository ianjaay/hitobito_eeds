# frozen_string_literal: true

module Eeds
  module ExcelImportsHelper
    def status_row_class(status)
      case status
      when :new then "table-success"
      when :updated then "table-info"
      when :unchanged then ""
      when :error then "table-danger"
      else ""
      end
    end
  end
end
