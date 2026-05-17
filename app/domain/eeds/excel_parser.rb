# frozen_string_literal: true

require "simple_xlsx_reader"

module Eeds
  # Parse un fichier Excel (.xlsx) uploadé et retourne les données
  # sous forme de tableau de hashes prêts pour l'import.
  class ExcelParser
    include Translatable

    attr_reader :rows, :headers, :error

    def initialize(file_content)
      @file_content = file_content
    end

    def parse
      doc = SimpleXlsxReader.open(StringIO.new(@file_content))
      sheet = doc.sheets.first

      if sheet.nil? || sheet.rows.size < 2
        @error = I18n.t("eeds.excel_imports.parser.no_data")
        return false
      end

      @headers = sheet.rows.first.map { |h| h.to_s.strip }
      @rows = sheet.rows[1..].map do |row|
        next if row.all?(&:blank?)
        @headers.each_with_index.each_with_object({}) do |(header, i), hash|
          hash[header] = row[i].to_s.strip if header.present?
        end
      end.compact

      if @rows.empty?
        @error = I18n.t("eeds.excel_imports.parser.no_data")
        return false
      end

      true
    rescue => e
      @error = I18n.t("eeds.excel_imports.parser.read_error", error: e.message)
      false
    end

    def size
      @rows&.size || 0
    end
  end
end
