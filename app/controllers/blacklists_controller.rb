# frozen_string_literal: true

#  Copyright (c) 2026, Éclaireuses et Éclaireurs du Sénégal. This file is part
#  of hitobito_eeds and licensed under the Affero General Public License
#  version 3 or later. See the COPYING file at the top-level directory or at
#  https://www.gnu.org/licenses/agpl-3.0.html.

class BlacklistsController < CrudController
  self.permitted_attrs = [:first_name, :last_name, :matricule_scout, :email,
    :phone_number, :reason, :reference_name, :reference_phone_number]

  self.sort_mappings = {last_name: :last_name, first_name: :first_name}

  skip_authorize_resource
  before_action :authorize_action

  def index
    @term = params[:q].presence
    @entries = Blacklist.search_by(@term).order(:last_name, :first_name)
  end

  def create
    assign_attributes
    entry.created_by = current_user
    if entry.save
      redirect_to blacklists_path,
        notice: I18n.t("blacklists.flash.created", default: "Entrée ajoutée à la liste.")
    else
      render :new, status: :unprocessable_content
    end
  end

  def export
    list = Blacklist.search_by(params[:q].presence).order(:last_name, :first_name)
    case params[:format]
    when "xlsx"
      send_data Export::Tabular::Blacklists::List.xlsx(list),
        type: :xlsx, filename: "blacklist_#{Time.zone.today}.xlsx"
    else
      send_data Export::Tabular::Blacklists::List.csv(list),
        type: :csv, filename: "blacklist_#{Time.zone.today}.csv"
    end
  end

  private

  def authorize_action
    case action_name
    when "index", "show", "new", "create", "export"
      authorize!(:index, Blacklist)
    else
      authorize!(:update, entry)
    end
  end
end
