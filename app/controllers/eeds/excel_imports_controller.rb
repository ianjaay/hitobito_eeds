# frozen_string_literal: true

module Eeds
  class ExcelImportsController < ApplicationController
    before_action :load_group
    before_action :authorize_import

    decorates :group
    helper_method :group

    # GET  /groups/:group_id/excel_imports/new
    def new
    end

    # POST /groups/:group_id/excel_imports/template
    def template
      generator = Eeds::ExcelTemplateGenerator.new(@group)
      xlsx_data = generator.generate

      send_data xlsx_data,
                filename: "modele_import_#{@group.name.parameterize}_#{Date.today}.xlsx",
                type: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
                disposition: "attachment"
    end

    # POST /groups/:group_id/excel_imports/preview
    def preview
      unless valid_file?
        flash[:alert] = t("eeds.excel_imports.invalid_file")
        redirect_to new_group_excel_imports_path(@group) and return
      end

      file_content = params[:excel_import][:file].read
      parser = Eeds::ExcelParser.new(file_content)

      unless parser.parse
        flash[:alert] = parser.error
        redirect_to new_group_excel_imports_path(@group) and return
      end

      @importer = Eeds::ExcelImporter.new(@group, parser.rows, user_ability: current_ability)
      @importer.preview

      # Stocker les données parsées en session pour l'import final
      session[:excel_import_data] = parser.rows.to_json
      session[:excel_import_group_id] = @group.id
    end

    # POST /groups/:group_id/excel_imports
    def create
      stored_data = session.delete(:excel_import_data)
      stored_group_id = session.delete(:excel_import_group_id)

      if stored_data.blank? || stored_group_id.to_i != @group.id
        flash[:alert] = t("eeds.excel_imports.session_expired")
        redirect_to new_group_excel_imports_path(@group) and return
      end

      rows = JSON.parse(stored_data)
      @importer = Eeds::ExcelImporter.new(@group, rows, user_ability: current_ability)
      @importer.import!

      flash_messages = []
      flash_messages << t("eeds.excel_imports.result.created", count: @importer.new_count) if @importer.new_count > 0
      flash_messages << t("eeds.excel_imports.result.updated", count: @importer.update_count) if @importer.update_count > 0
      flash_messages << t("eeds.excel_imports.result.roles", count: @importer.role_count) if @importer.role_count > 0
      flash_messages << t("eeds.excel_imports.result.failed", count: @importer.failure_count) if @importer.failure_count > 0

      if @importer.failure_count > 0
        flash[:alert] = flash_messages.join(" | ")
        error_details = @importer.results.select { |r| r[:status] == :error }
                                         .first(10)
                                         .map { |r| "Ligne #{r[:row]} : #{r[:errors].join(', ')}" }
        flash[:alert] += "\n" + error_details.join("\n") if error_details.present?
      else
        flash[:notice] = flash_messages.join(" | ")
      end

      redirect_to group_people_path(@group)
    end

    private

    def load_group
      @group = Group.find(params[:group_id])
    end

    def authorize_import
      authorize! :new, @group.roles.new
    end

    def valid_file?
      file = params.dig(:excel_import, :file)
      file.present? &&
        file.respond_to?(:content_type) &&
        file.content_type =~ /spreadsheetml|excel|octet-stream/
    end

    def group
      @group
    end
  end
end
