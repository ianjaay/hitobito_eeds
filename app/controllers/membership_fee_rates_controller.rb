# frozen_string_literal: true

#  Copyright (c) 2026, Éclaireuses et Éclaireurs du Sénégal. This file is part
#  of hitobito_eeds and licensed under the Affero General Public License
#  version 3 or later. See the COPYING file at the top-level directory or at
#  https://www.gnu.org/licenses/agpl-3.0.html.

# Grille tarifaire nationale (year × branche → montant). Géré par les
# Trésoriers et Commissaires Nationaux (permission `:finance` au layer
# National, soit `groups_with_permission(:finance)` au National).
class MembershipFeeRatesController < CrudController
  self.permitted_attrs = [:year, :branche, :amount_cents, :currency, :description]

  decorates :group

  skip_authorize_resource
  before_action :authorize_action

  def index
    @year = params[:year].presence&.to_i || default_year
    @rates = MembershipFeeRate.for_year(@year).order(:branche)
  end

  private

  def default_year
    Time.zone.today.year
  end

  def list_entries
    MembershipFeeRate.order(year: :desc, branche: :asc)
  end

  def group
    @group ||= Group.find(params[:group_id])
  end

  def authorize_action
    if %w[index show].include?(action_name)
      authorize!(:show, MembershipFee.new(group: group))
    else
      authorize!(:create, MembershipFee.new(group: group))
    end
  end

  def return_path
    group_membership_fee_rates_path(@group, year: @year)
  end
end
