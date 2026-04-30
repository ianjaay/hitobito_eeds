# frozen_string_literal: true

#  Copyright (c) 2026, Éclaireuses et Éclaireurs du Sénégal. This file is part
#  of hitobito_eeds and licensed under the Affero General Public License
#  version 3 or later. See the COPYING file at the top-level directory or at
#  https://www.gnu.org/licenses/agpl-3.0.html.

# Effectifs annuels d'un Groupe Local. Le calcul automatique se fait via
# `Eeds::MemberCountGenerator`; les effectifs peuvent ensuite être ajustés
# manuellement par les responsables locaux.
class MemberCountsController < CrudController
  self.permitted_attrs = MemberCount::COUNT_COLUMNS.dup

  decorates :group

  skip_authorize_resource
  before_action :authorize_action

  def index
    @year = params[:year].presence&.to_i || default_year
    @counts = MemberCount.where(group_id: descendant_group_ids)
      .for_year(@year)
      .includes(:group)
      .order("groups.name")
  end

  def recompute
    year = (params[:year].presence || default_year).to_i
    census = Census.find_by(year: year)
    Eeds::MemberCountGenerator.new(group: group, year: year, census: census).run!
    redirect_to group_member_counts_path(@group, year: year),
      notice: I18n.t("member_counts.flash.recomputed", default: "Effectifs recalculés.")
  end

  private

  def default_year
    Census.current&.year || Time.zone.today.year
  end

  def descendant_group_ids
    g = group
    Group.where("lft >= ? AND rgt <= ?", g.lft, g.rgt).pluck(:id)
  end

  def model_scope
    MemberCount.where(group_id: group.id)
  end

  def group
    @group ||= Group.find(params[:group_id])
  end

  def authorize_action
    if %w[index show].include?(action_name)
      authorize!(:show, MemberCount.new(group: group))
    elsif action_name == "recompute"
      authorize!(:update, MemberCount.new(group: group))
    else
      authorize!(:update, entry)
    end
  end

  def return_path
    group_member_counts_path(@group, year: @year || default_year)
  end
end
