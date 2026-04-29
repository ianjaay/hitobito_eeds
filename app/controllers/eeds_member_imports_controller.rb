# frozen_string_literal: true

#  Copyright (c) 2026, Éclaireuses et Éclaireurs du Sénégal. This file is part
#  of hitobito_eeds and licensed under the Affero General Public License
#  version 3 or later. See the COPYING file at the top-level directory or at
#  https://www.gnu.org/licenses/agpl-3.0.html.

# Controller pour l'import CSV des membres EEDS.
#
# Workflow :
#   1. GET  /eeds_member_imports/new      → formulaire d'upload
#   2. POST /eeds_member_imports/preview  → dry-run, affiche le tableau
#   3. POST /eeds_member_imports          → commit, redirige vers root
#
# Accès : réservé aux administrateurs (permission :admin via CanCan).
class EedsMemberImportsController < ApplicationController
  before_action :authorize_action

  def new
  end

  def preview
    @result = build_importer.dry_run
    render :preview
  end

  def create
    @result = build_importer.commit
    if @result.success?
      redirect_to root_path,
        notice: t("eeds_member_imports.flash.success", count: @result.total)
    else
      render :preview
    end
  end

  private

  def build_importer
    file = params[:file]
    raise ActionController::ParameterMissing, :file unless file

    Eeds::MemberCsvImporter.new(file.respond_to?(:read) ? file.read : file.to_s)
  end

  def authorize_action
    authorize!(:admin, Person)
  end
end
